require "notifications/review_request_notification"

class RecycleNotification < ReviewRequestNotification
  def initialize(issue:, comment:)
    super(
      issue: issue,
      icon: :recycle,
      link: comment.html_url
    )
  end

  private

    def action
      "Review changes"
    end

    def mentions
      @_mentions ||= issue.peer_reviewers.map(&:chat_name)
    end
end
