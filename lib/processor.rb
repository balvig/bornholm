require "active_support"
require "configuration"
require "issue_closer"
require "issue_delegator"
require "notifier"
require "labeler"
require "project_manager"
require "notifications/blocking_pr_notification"
require "notifications/recycle_notification"
require "notifications/review_complete_notification"
require "notifications/ready_for_review_notification"

class Processor
  cattr_accessor :config

  def initialize(payload, config: {})
    @payload = payload
    @config = Configuration.new(config.symbolize_keys)
    @logs = []
  end

  def process
    return if event_triggered_by_bot?

    notify_new_pull_request
    notify_unwip
    notify_blocker
    notify_recycle
    notify_review
    add_labels
    move_new_issue_to_project
    delegate_issue
    close_stale_issues
    logs.join("\n")
  end

  private

    attr_reader :payload, :config, :logs

    def log(msg)
      logs << msg
    end

    def notify_new_pull_request
      return unless payload.pull_request_action?
      return unless payload.action.opened?
      return if payload.issue.wip?

      log "Notifying new pull request"
      notify ReadyForReviewNotification.new(issue: payload.issue)
    end

    def notify_unwip
      return unless payload.unwip_action?

      log "Notifying unwip"
      notify ReadyForReviewNotification.new(issue: payload.issue)
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

    def delegate_issue
      if payload.label_added?
        log "Label added, pondering whether to move"
        IssueDelegator.new(label: payload.label, issue: payload.issue, prefix: config.move_to_prefix).run
      end
    end

    def close_stale_issues
      if payload.action.opened?
        log "Closing stale issues"
        IssueCloser.new(repo, weeks: config.stale_issue_weeks).run
      end
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
