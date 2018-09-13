require "test_helper"

class ProcessorTest < Minitest::Test
  class TestChatClient
    cattr_accessor :deliveries do
      []
    end

    def ping(args = {})
      deliveries << args
    end
  end

  def setup
    ENV["TZ"] = "UTC"
    Time.stubs(:now).returns(Time.at(0))
    Cp8.github_client = github
    Cp8.chat_client = TestChatClient.new
  end

  def test_closing_stale_prs
    github.expects(:search_issues).with("repo:balvig/cp-8 is:open updated:<1969-12-04T00:00:00+00:00").once.returns(stub(items: [{ number: 1, id: 1 }]))
    github.expects(:add_comment)
    github.expects(:close_issue).with("balvig/cp-8", 1)
    github.expects(:add_labels_to_an_issue).with("balvig/cp-8", 1, [:Icebox]).once

    process_payload(:issue_wip, config: { stale_issue_weeks: 4 } )
  end

  def test_not_closing_stales_prs_if_not_configrued
    github.expects(:search_issues).never

    process_payload(:issue_wip)
  end

  def test_not_reacting_to_own_posts
    github.stubs(:search_issues).returns(stub(items: [{ number: 1 }]))
    github.expects(:add_comment).never
    github.expects(:close_issue).never

    process_payload(:cp8_commented)
  end

  def test_creating_pr_with_wip_label
    github.expects(:label).with("balvig/cp-8", :WIP).once.raises(Octokit::NotFound)
    github.expects(:add_label).with("balvig/cp-8", :WIP, "5319e7").once
    github.expects(:add_labels_to_an_issue).with("balvig/cp-8", 1, [:WIP]).once

    process_payload(:pull_request_wip)
  end

  def test_adding_wip_label_when_title_has_multiple_prefixes
    github.expects(:add_labels_to_an_issue).with("balvig/cp-8", 1, [:WIP]).once

    process_payload(:pull_request_with_multiple_prefixes)
  end

  def test_ignoring_label_if_already_added
    github.expects(:labels_for_issue).with("balvig/cp-8", 1).twice.returns([stub(name: "WIP")])
    github.expects(:add_labels_to_an_issue).never

    process_payload(:pull_request_wip)
  end

  def test_adding_wip_label
    github.expects(:label).with("balvig/cp-8", :WIP).once.raises(Octokit::NotFound)
    github.expects(:add_label).with("balvig/cp-8", :WIP, "5319e7").once
    github.expects(:add_labels_to_an_issue).with("balvig/cp-8", 1, [:WIP]).once

    process_payload(:pull_request_added_wip)
  end

  def test_not_adding_labels_to_plain_issues
    github.expects(:add_labels_to_an_issue).never

    process_payload(:issue_wip)
  end

  def test_removing_wip_label
    github.stubs(:labels_for_issue).with("balvig/cp-8", 1).returns([stub(name: "WIP")])
    github.expects(:remove_label).with("balvig/cp-8", 1, :WIP).once

    process_payload(:pull_request_removed_wip)
  end

  def test_notifying_recycle_requests
    github.expects(:pull_request_reviews).with("balvig/cp-8", 1).once.returns(
      [stub(user: { login: "reviewer" })]
    )

    process_payload(:comment_recycle)

    assert_equal ":recycle: Review changes - <@reviewer> please", last_notification[:text]
    assert_equal "balvig", last_notification_attachment[:author_name]
    assert_equal "https://avatars.githubusercontent.com/u/104138?v=3&size=16", last_notification_attachment[:author_icon]
    assert_equal "<https://github.com/balvig/cp-8/pull/1#issuecomment-189682850|#1 Test for PR>", last_notification_attachment[:fields].first[:value]
  end

  def test_notifying_recycle_dismissals
    process_payload(:review_dismissed)

    assert_equal ":recycle: Review changes - <@reviewer> please", last_notification[:text]
    assert_equal "submitter", last_notification_attachment[:author_name]
  end

  def test_notifying_new_large_pull_requests
    github.stubs(:pull_request).returns(additions: 101)
    process_payload(:pull_request)

    assert_equal ":mag: New PR", last_notification[:text]
  end

  def test_notifying_new_small_pull_requests_without_mention
    github.stubs(:pull_request).returns(additions: 5, deletions: 5)
    process_payload(:pull_request)

    assert_equal ":mag: Small PR", last_notification[:text]
    assert_equal ":mag: Small PR", last_notification[:fallback]
    assert_equal "+5 / -5", last_notification_attachment[:fields].last[:value]
  end

  def test_notifying_pull_requests_with_requested_reviewers
    github.stubs(:pull_request).returns(additions: 5)
    github.expects(:pull_request_review_requests).with("balvig/cp-8", 1).once.returns(
      stub(users: [{ login: "reviewer" }])
    )
    process_payload(:pull_request)

    assert_equal ":mag: Small PR - <@reviewer> please", last_notification[:text]
  end

  def test_notifying_unwipped_issues
    process_payload(:pull_request_removed_wip)

    assert_equal ":mag: Small PR", last_notification[:text]
  end

  def test_notifying_requested_changes
    process_payload(:changes_requested)

    assert_equal ":x: <https://github.com/cookpad/cp-8/pull/6561#pullrequestreview-85607834|#6561 changes required> by reviewer _(cc <@submitter>)_", last_notification[:text]
  end

  def test_notifying_approval
    process_payload(:approval)

    assert_equal ":white_check_mark: <https://github.com/cookpad/cp-8/pull/6561#pullrequestreview-85607834|#6561 was approved> by reviewer _(cc <@submitter>)_", last_notification[:text]
  end

  def test_moving_issues_when_labeled
    github.expects(:create_issue).with("cookpad/dummy-squad", "Issue title", "_Moved from https://github.com/balvig/cp-8/issues/2_\n\n---\nIssue body").once
    github.expects(:close_issue).with("balvig/cp-8", 2)

    process_payload(:move_to_label, config: { move_to_prefix: "move-to" } )
  end

  private

    def process_payload(file, config: default_config)
      process(create_payload(file), config: config)
    end

    def process(payload, config: default_config)
      Processor.new(payload, config: config).process
    end

    def default_config
      { review_channel: "#notification-test" }
    end

    def create_payload(file)
      json = File.read File.expand_path("../fixtures/#{file}.json", __FILE__), encoding: "UTF-8"
      Payload.new_from_json(json)
    end

    def github
      @_github ||= build_fake_github
    end

    def build_fake_github
      stub(
        label: true,
        add_label: true,
        labels_for_issue: [],
        search_issues: stub(items: []),
        pull_request_review_requests: stub(users: []),
        pull_request: extended_pull_request_data
      )
    end

    def extended_pull_request_data
      {
        additions: 1,
        deletions: 1
      }
    end

    def last_notification
      Cp8.chat_client.deliveries.last
    end

    def last_notification_attachment
      last_notification[:attachments].last
    end
end
