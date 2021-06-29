require "notifications/review_request_notification"

class ReadyForReviewNotification < ReviewRequestNotification
  def initialize(issue:, mention_threshold:)
    super(
      issue: issue,
      icon: :mag
    )
    @mention_threshold = mention_threshold
  end

  private

    attr_reader :mention_threshold

    def action
      if small_pr?
        "Small PR"
      else
        "New PR"
      end
    end

    def mentions
      if small_pr?
        requested_reviewers
      else
        []
      end
    end

    def requested_reviewers
      @_requested_reviewers ||= issue.requested_reviewers.map(&:chat_name)
    end

    def small_pr?
      return true if mention_threshold.zero?

      issue.additions <= mention_threshold
    end
end
