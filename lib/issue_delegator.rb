class IssueDelegator
  def initialize(label:, issue:, prefix:)
    @label = label
    @issue = issue
    @prefix = prefix
  end

  def run
    return if prefix.blank?

    if label.prefix == prefix
      move_issue
    end
  end

  private

    attr_reader :label, :issue, :prefix

    def move_issue
      create_copy_of_issue_in_selected_repo
      close_original_issue
    rescue Octokit::NotFound
      post_error_comment
    end

    def create_copy_of_issue_in_selected_repo
      github.create_issue(target_repo, issue.title, moved_issue_body)
    end

    def close_original_issue
      github.close_issue(issue.repo, issue.number)
    end

    def target_repo
      label.suffix
    end

    def github
      Cp8.github_client
    end

    def moved_issue_body
      link_to_original_issue + issue.body
    end

    def link_to_original_issue
      "_Moved from #{issue.html_url} (cc @#{issue.user.login})_\n\n---\n"
    end

    def post_error_comment
      github.add_comment(issue.repo, issue.number, error_message)
    end

    def error_message
      <<~TEXT
        [BOOooop...] I tried to move this issue to #{target_repo}, but couldn't.

        Maybe I don't have the right permissions?

        Try adding me to that repo and try again!
      TEXT
    end
end
