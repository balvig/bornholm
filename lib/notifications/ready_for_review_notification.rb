require "notifications/review_request_notification"

class ReadyForReviewNotification < ReviewRequestNotification
  def initialize(issue:)
    super(
      issue: issue,
      icon: :mag
    )
  end

  private

    def action
      if issue.small?
        "Quick Review"
      else
        "Review"
      end
    end

    def mentions
      if issue.small?
        requested_reviewers
      else
        []
      end
    end

    def requested_reviewers
      @_requested_reviewers ||= issue.requested_reviewers.map(&:chat_name)
    end
end
