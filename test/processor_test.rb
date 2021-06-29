require "test_helper"

class ProcessorTest < Minitest::Test
  PROJECT_COLUMN_ID = 49

  class TestChatClient
    attr_reader :deliveries

    def initialize
      @deliveries = []
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
    BuddyResolver.mappings = []
  end

  def test_closing_stale_prs
    github.expects(:search_issues).with("repo:balvig/cp-8 is:open updated:<1969-12-04T00:00:00+00:00").once.returns(stub(items: [{ number: 1, id: 1 }]))
    github.expects(:add_comment)
    github.expects(:close_issue).with("balvig/cp-8", 1)
    github.expects(:add_labels_to_an_issue).with("balvig/cp-8", 1, [:Icebox]).once

    process_payload(:issue, config: { stale_issue_weeks: 4 } )
  end

  def test_not_closing_stales_prs_if_not_configrued
    github.expects(:search_issues).never

    process_payload(:issue)
  end

  def test_not_reacting_to_own_posts
    github.stubs(:search_issues).returns(stub(items: [{ number: 1 }]))
    github.expects(:add_comment).never
    github.expects(:close_issue).never

    process_payload(:cp8_commented)
  end

  def test_adding_new_issues_to_project
    github.expects(:create_project_card).with(49, content_id: 137013866, content_type: "Issue"). once

    process_payload(:issue, config: { project_column_id: PROJECT_COLUMN_ID } )
  end

  def test_adding_new_issues_to_project_if_column_not_in_project
    github.expects(:create_project_card).raises(Octokit::NotFound)

    process_payload(:issue, config: { project_column_id: PROJECT_COLUMN_ID } )
  end

  def test_not_adding_new_pr_to_project
    github.expects(:create_project_card).never

    process_payload(:pull_request, config: { project_column_id: PROJECT_COLUMN_ID } )
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

  def test_notifying_new_large_pull_requests_with_custom_mention_threshold
    github.stubs(:pull_request).returns(additions: 50)
    process_payload(:pull_request, config: { mention_threshold: 49, review_channel: "#notification-test" } )

    assert_equal ":mag: New PR", last_notification[:text]
  end

  def test_notifying_new_small_pull_requests_with_custom_mention_threshold_and_with_mention
    github.stubs(:pull_request).returns(additions: 150, deletions: 75)
    github.expects(:pull_request_review_requests).with("balvig/cp-8", 1).once.returns(
      stub(users: [{ login: "reviewer" }])
    )
    process_payload(:pull_request, config: { mention_threshold: 200, review_channel: "#notification-test" } )

    assert_equal ":mag: Small PR - <@reviewer> please", last_notification[:text]
  end

  def test_notifying_new_large_pull_requests_with_mention_threshold_disabled
    github.stubs(:pull_request).returns(additions: 150, deletions: 75)
    github.expects(:pull_request_review_requests).with("balvig/cp-8", 1).once.returns(
      stub(users: [{ login: "reviewer" }])
    )
    process_payload(:pull_request, config: { mention_threshold: 0, review_channel: "#notification-test" } )

    assert_equal ":mag: Small PR - <@reviewer> please", last_notification[:text]
  end

  def test_repo_shown_in_attachment
    process_payload(:pull_request)

    assert_equal "balvig/cp-8", last_notification_attachment[:fields].last[:value]
  end

  def test_notifying_new_small_pull_requests_without_mention
    github.stubs(:pull_request).returns(additions: 5, deletions: 5)
    process_payload(:pull_request)

    assert_equal ":mag: Small PR", last_notification[:text]
    assert_equal ":mag: Small PR", last_notification[:fallback]
    assert_equal "+5 / -5", last_notification_attachment[:fields].second[:value]
  end

  def test_notifying_pull_requests_with_requested_reviewers
    github.stubs(:pull_request).returns(additions: 5)
    github.expects(:pull_request_review_requests).with("balvig/cp-8", 1).once.returns(
      stub(users: [{ login: "reviewer" }])
    )
    process_payload(:pull_request)

    assert_equal ":mag: Small PR - <@reviewer> please", last_notification[:text]
  end

  def test_notifying_drafts_submitted_for_review
    process_payload(:ready_for_review)

    assert_equal ":mag: Small PR", last_notification[:text]
  end

  def test_not_notifying_drafted_prs
    process_payload(:pull_request_draft)

    assert_nil last_notification
  end

  def test_notifying_blocked_prs
    process_payload(:pull_request_added_blocker)

    assert_equal ":rotating_light: Blocking PR needs review - <!here> please", last_notification[:text]
  end

  def test_notifying_requested_changes
    process_payload(:changes_requested)

    assert_equal ":speech_balloon: <https://github.com/cookpad/cp-8/pull/6561#pullrequestreview-85607834|#6561 reviewed> by reviewer _(cc <@submitter>)_", last_notification[:text]
    assert_equal "<https://github.com/cookpad/cp-8/pull/6561#pullrequestreview-85607834|Generate link with a correct region>", last_notification_attachment[:fields].first[:value]
  end

  def test_notifying_approval
    process_payload(:approval)

    assert_equal ":white_check_mark: <https://github.com/cookpad/cp-8/pull/6561#pullrequestreview-85607834|#6561 was approved> by reviewer _(cc <@submitter>)_", last_notification[:text]
    assert_equal "<https://github.com/cookpad/cp-8/pull/6561#pullrequestreview-85607834|Generate link with a correct region>", last_notification_attachment[:fields].first[:value]
  end

  def test_not_notifying_reviews_from_submitter
    process_payload(:submitter_review)

    assert_nil last_notification
  end

  def test_assigning_buddy_on_new_pr
    BuddyResolver.mappings = [["balvig", "knack"]]
    github.expects(:request_pull_request_review).with("balvig/cp-8", 1, reviewers: ["knack"])

    process_payload(:pull_request)
  end

  def test_assigning_buddy_on_ready_for_review
    BuddyResolver.mappings = [["balvig", "knack"]]
    github.expects(:request_pull_request_review).with("cookpad/cp8", 83, reviewers: ["knack"])

    process_payload(:ready_for_review)
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
