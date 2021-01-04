class BuddyAssignment
  def initialize(issue)
    @issue = issue
  end

  def assign
    return unless buddy

    request_review
  end

  private

    attr_reader :issue

    def buddy
      @_buddy ||= BuddyResolver.new(issue.user).buddy
    end

    def request_review
      github.request_pull_request_review(issue.repo, issue.number,  reviewers: [buddy.login])
    end

    def github
      Cp8.github_client
    end
end
