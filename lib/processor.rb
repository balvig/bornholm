require "active_support"
require "buddy_mention"
require "configuration"
require "issue_closer"
require "notifier"
require "labeler"
require "project_manager"
require "notifications/blocking_pr_notification"
require "notifications/recycle_notification"
require "notifications/review_complete_notification"
require "notifications/ready_for_review_notification"

class Processor
  def initialize(payload, config: {})
    @payload = payload
    @config = Configuration.new(config.symbolize_keys)
    @logs = []
  end

  def process
    return if event_triggered_by_bot?

    mention_buddy
    notify_new_pull_request
    notify_ready_for_review
    notify_unwip
    notify_blocker
    notify_recycle
    notify_review
    add_labels
    move_new_issue_to_project
    close_stale_issues
    logs.join("\n")
  end

  private

    attr_reader :payload, :config, :logs

    def log(msg)
      logs << msg
    end

    def mention_buddy
      return unless payload.pull_request_action?
      return unless payload.action.opened? || payload.action.ready_for_review?
      return if payload.issue.wip?
      return if payload.issue.draft?

      log "Mentioning buddy"
      BuddyMention.new(payload.issue).mention
    end

    def notify_new_pull_request
      return unless payload.pull_request_action?
      return unless payload.action.opened?
      return if payload.issue.wip?
      return if payload.issue.draft?

      log "Notifying new pull request"
      send_ready_for_review_notification
    end

    def notify_ready_for_review
      return unless payload.action.ready_for_review?

      log "Notifying pull request ready for review"
      send_ready_for_review_notification
    end

    def notify_unwip
      return unless payload.unwip_action?

      log "Notifying unwip"
      send_ready_for_review_notification
    end

    def notify_blocker
      return unless payload.blocker_action?

      log "Notifying blocking PR "
      notify BlockingPrNotification.new(issue: payload.issue)
    end

    def notify_recycle
      return unless payload.recycle_request?

      log "Notifying recycle request"
      notify RecycleNotification.new(issue: payload.issue, trigger: payload.comment || payload.review)
    end

    def notify_review
      return unless payload.review_action?

      log "Notifying review"
      notify ReviewCompleteNotification.new(review: payload.review, issue: payload.issue)
    end

    def add_labels
      log "Updating labels"
      Labeler.new(payload.issue).run
    end

    def move_new_issue_to_project
      if payload.opened_new_issue?
        log "Adding card for new issue in configured project column"
        log ProjectManager.new(issue: payload.issue, project_column_id: config.project_column_id).run
      end
    end

    def close_stale_issues
      if payload.action.opened?
        log "Closing stale issues"
        IssueCloser.new(repo, weeks: config.stale_issue_weeks).run
      end
    end

    def send_ready_for_review_notification
      notify ReadyForReviewNotification.new(
        issue: payload.issue, mention_threshold: config.mention_threshold
      )
    end

    def notify(notification)
      notifier.deliver(notification)
    end

    def notifier
      @_notifier ||= Notifier.new(channel: config.review_channel)
    end

    def event_triggered_by_bot?
      payload.sender_bot?
    end

    def repo
      payload.repo
    end

    def github
      Cp8.github_client
    end
end
