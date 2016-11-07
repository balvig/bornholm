require "test_helper"

class PayloadTest < Minitest::Test
  def setup
    ENV["TZ"] = "UTC"
    Time.stubs(:now).returns(Time.at(0))
    Cp8.github_client = github
  end

  def test_closing_stale_prs
    github.expects(:search_issues).with("repo:balvig/cp-8 is:open updated:<1969-11-27T00:00:00+00:00").once.returns(stub(items: [stub(number: 1)]))
    github.expects(:add_comment)
    create_payload(:pull_request_removed_wip).process
  end

  def test_creating_labels_if_they_dont_exist
    github.expects(:label).with("balvig/cp-8", :Reviewed).once.raises(Octokit::NotFound)
    github.expects(:add_label).with("balvig/cp-8", :Reviewed, "207de5").once
    github.expects(:add_labels_to_an_issue).once
    create_payload(:comment_plus_one).process
  end

  def test_adding_reviewed_label_if_given_emoji_plus_one
    github.expects(:add_labels_to_an_issue).with("balvig/cp-8", 1, [:Reviewed]).once
    create_payload(:comment_plus_one).process
  end

  def test_adding_reviewed_label_if_given_legacy_plus_one
    github.expects(:add_labels_to_an_issue).with("balvig/cp-8", 1, [:Reviewed]).once
    create_payload(:comment_legacy_plus_one).process
  end

  def test_adding_reviewed_label_if_approved_review_submitted
    github.expects(:add_labels_to_an_issue).with("balvig/cp-8", 1, [:Reviewed]).once
    create_payload(:review_approved).process
  end

  def test_removing_reviewed_label_if_given_recyle
    github.expects(:labels_for_issue).with("balvig/cp-8", 1).once.returns([stub(name: "Reviewed")])
    github.expects(:remove_label).with("balvig/cp-8", 1, :Reviewed).once
    create_payload(:comment_recycle).process
  end

  def test_ignoring_comment_if_already_added
    github.expects(:labels_for_issue).with("balvig/cp-8", 1).once.returns([stub(name: "Reviewed")])
    github.expects(:add_labels_to_an_issue).never
    create_payload(:comment_plus_one).process
  end

  def test_not_adding_reviewed_label_if_myself
    github.expects(:add_labels_to_an_issue).never
    create_payload(:comment_own).process
  end

  def test_not_adding_labels_to_plain_issues
    github.expects(:add_labels_to_an_issue).never
    create_payload(:issue_comment).process
  end

  def test_creating_pr_with_wip_label
    github.expects(:label).with("balvig/cp-8", :WIP).once.raises(Octokit::NotFound)
    github.expects(:add_label).with("balvig/cp-8", :WIP, "5319e7").once
    github.expects(:add_labels_to_an_issue).with("balvig/cp-8", 1, [:WIP]).once
    create_payload(:pull_request_wip).process
  end

  def test_adding_wip_label_and_removing_reviewed_label
    github.stubs(:labels_for_issue).with("balvig/cp-8", 1).returns([stub(name: "Reviewed")])
    github.expects(:label).with("balvig/cp-8", :WIP).once.raises(Octokit::NotFound)
    github.expects(:add_label).with("balvig/cp-8", :WIP, "5319e7").once
    github.expects(:add_labels_to_an_issue).with("balvig/cp-8", 1, [:WIP]).once
    github.expects(:remove_label).with("balvig/cp-8", 1, :Reviewed).once
    create_payload(:pull_request_added_wip).process
  end

  def test_removing_wip_label
    github.stubs(:labels_for_issue).with("balvig/cp-8", 1).returns([stub(name: "WIP")])
    github.expects(:remove_label).with("balvig/cp-8", 1, :WIP).once
    create_payload(:pull_request_removed_wip).process
  end

  private

    def create_payload(file)
      json = File.read File.expand_path("../fixtures/#{file}.json", __FILE__), encoding: "UTF-8"
      Payload.new_from_json(json)
    end

    def github
      @github ||= stub(label: true, add_label: true, labels_for_issue: [], search_issues: stub(items: []))
    end
end
