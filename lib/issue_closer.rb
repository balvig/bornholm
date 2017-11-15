class IssueCloser
  WEEK = 7 * 24 * 60 * 60

  def initialize(repo, weeks: nil)
    @repo = repo
    @weeks = weeks || 4
  end

  def run
    stale_issues.each do |issue|
      github.close_issue(issue.repo, issue.number)
      github.add_comment(issue.repo, issue.number, comment)
      Label.new(:Icebox).add_to(issue)
    end
  end

  private

    attr_reader :repo, :weeks

    def comment
      <<~TEXT
        [BEEP BOOP] Hi there!

        This issue/PR hasn't been updated for _#{weeks} weeks_ so closing for now.

        Feel free to re-open in the future if/when it becomes relevant again! :heart:

        ---

        _Configure by adding `?config[stale_issue_weeks]=...` to the webhook._
      TEXT
    end

    def stale_issues
      stale_issue_data.map do |data|
        Issue.new(data.to_h.merge(repo: repo))
      end
    end

    def stale_issue_data
      github.search_issues("repo:#{repo} is:open updated:<#{stale_issue_cutoff_date}").items
    end

    def stale_issue_cutoff_date
      (Time.now - weeks * WEEK).iso8601
    end

    def github
      Cp8.github_client
    end
end
