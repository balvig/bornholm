class IssueDelegator
  def initialize(label:, issue:, prefix:)
    @label = label
    @issue = issue
    @prefix = prefix
  end

  def run
    return if prefix.blank?

    if label.prefix == prefix
      create_copy_of_issue_in_selected_repo
      close_original_issue
    end
  end

  private

    attr_reader :label, :issue, :prefix

    def create_copy_of_issue_in_selected_repo
      github.create_issue(label.suffix, issue.title, moved_issue_body)
    end

    def close_original_issue
      github.close_issue(issue.repo, issue.number)
    end

    def github
      Cp8.github_client
    end

    def moved_issue_body
      link_to_original_issue + issue.body
    end

    def link_to_original_issue
      "_Moved from #{issue.html_url}_\n\n---\n"
    end
end
