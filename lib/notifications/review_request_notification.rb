require "notifications/notification"

class ReviewRequestNotification < Notification
  def initialize(issue:, icon:, link: nil)
    @issue = issue
    @icon = icon
    @link = link || issue.html_url
  end

  def text
    ":#{icon}: #{action}#{mention_text}"
  end

  def attachments
    [attachment]
  end

  private

    attr_reader :issue, :icon, :action, :mentions, :link

    def mention_text
      return if mentions.empty?

      " - " + mentions.join(", ") + " please"
    end

    def mentions
      raise "Define in child class"
    end

    def action
      raise "Define in child class"
    end

    def attachment
      {
        author_name: issue.user.login,
        author_icon: issue.user.avatar_url,
        fields: [issue_field, changes_field, repo_field]
      }
    end

    def issue_field
      {
        title: "Pull Request",
        value: "<#{link}|##{issue.number} #{issue.title}>",
        short: true
      }
    end

    def changes_field
      {
        title: "Diff",
        value: "+#{issue.additions} / -#{issue.deletions}",
        short: true
      }
    end

    def repo_field
      {
        title: "Repo",
        value: issue.repo,
        short: true
      }
    end
end
