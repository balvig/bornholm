require "notifications/review_request_notification"

class BlockingPrNotification < ReviewRequestNotification
  EVERYONE = "<!here>"

  def initialize(issue:)
    super(
      issue: issue,
      icon: :zap
    )
  end

  private

    def action
      "Blocking PR needs review"
    end

    def mentions
      [EVERYONE]
    end
end
