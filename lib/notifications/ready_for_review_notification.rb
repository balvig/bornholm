require "notifications/review_request_notification"

class ReadyForReviewNotification < ReviewRequestNotification
  EVERYONE = "<!here>"

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
      return [] unless issue.small?

      if requested_reviewers.any?
        requested_reviewers
      else
        [EVERYONE]
      end
    end

    def requested_reviewers
      @_requested_reviewers ||= issue.requested_reviewers.map(&:chat_name)
    end
end
