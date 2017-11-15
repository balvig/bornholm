require "test_helper"

class ProcessorTest < Minitest::Test
  CP8_USER_ID = 9999

  def setup
    ENV["TZ"] = "UTC"
    Time.stubs(:now).returns(Time.at(0))
    Cp8.github_client = github
    Cp8.trello_client = trello
  end

  def test_closing_stale_prs
    github.expects(:search_issues).with("repo:balvig/cp-8 is:open updated:<1969-12-04T00:00:00+00:00").once.returns(stub(items: [{ number: 1 }]))
    github.expects(:add_comment)
    github.expects(:close_issue).with("balvig/cp-8", 1)
    github.expects(:add_labels_to_an_issue).with("balvig/cp-8", 1, [:Icebox]).once

    process_payload(:pull_request_removed_wip)
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

  def test_removing_wip_label
    github.stubs(:labels_for_issue).with("balvig/cp-8", 1).returns([stub(name: "WIP")])
    github.expects(:remove_label).with("balvig/cp-8", 1, :WIP).once

    process_payload(:pull_request_removed_wip)
  end

  def test_not_adding_labels_to_plain_issues
    github.expects(:add_labels_to_an_issue).never

    process_payload(:issue_wip)
  end

  def test_updating_trello_when_submitting_pr
    trello.expects(:update_card).with("1234", status: :finish).once
    trello.expects(:attach).with("1234", url: "https://github.com/balvig/cp-8/pull/3")

    process_payload(:pull_request_delivers)
  end

  def test_updating_trello_when_closing_pr
    trello.expects(:update_card).with("1234", status: :accept).once

    process_payload(:pull_request_closed)
  end

  def test_updating_multiple_card_when_closing_pr
    trello.expects(:update_card).with("1234", status: :accept).once
    trello.expects(:update_card).with("5678", status: :accept).once

    process_payload(:pull_request_closed_multiple)
  end

  def test_keeping_cards_in_accepted_column_when_editing_closed_pr
    trello.expects(:update_card).with("1234", status: :finish).never
    trello.expects(:update_card).with("1234", status: :accept).once

    process_payload(:closed_pull_request_edited)
  end

  private

    def process_payload(file)
      process create_payload(file)
    end

    def process(payload)
      Processor.new(payload).process
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
        user: stub(id: CP8_USER_ID),
        label: true,
        add_label: true,
        labels_for_issue: [],
        search_issues: stub(items: [])
      )
    end

    def trello
      @_trello ||= stub
    end
end
