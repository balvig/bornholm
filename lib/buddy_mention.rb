class BuddyMention
  def initialize(issue)
    @issue = issue
  end

  def mention
    return unless buddy

    request_review
    post_comment
  end

  private

    attr_reader :issue

    def buddy
      @_buddy ||= BuddyResolver.new(issue.user).buddy
    end

    def request_review
      github.request_pull_request_review(issue.repo, issue.number,  reviewers: [buddy.login])
    end

    def post_comment
      github.add_comment(issue.repo, issue.number, comment_body)
    end

    def comment_body
      <<~TEXT
      **[Try-out]**

      @#{buddy.login} is your buddy as part of the
      [Buddy system](https://github.com/cookpad/web-chapter/issues/410) try-out,
      and has been added as a reviewer.
      TEXT
    end

    def github
      Cp8.github_client
    end
end
