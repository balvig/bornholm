require "notifications/review_request_notification"

class RecycleNotification < ReviewRequestNotification
  def initialize(issue:, trigger:)
    @trigger = trigger
    super(
      issue: issue,
      icon: :recycle,
      link: trigger.html_url
    )
  end

  private

    attr_reader :trigger

    def action
      "Review changes"
    end

    def mentions
      @_mentions ||= find_mentions.map(&:chat_name)
    end

    def find_mentions
      if trigger.is_a?(Comment)
        issue.peer_reviewers
      else
        [trigger.user]
      end
    end
end
