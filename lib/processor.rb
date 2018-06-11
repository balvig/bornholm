require "active_support"
require "configuration"
require "issue_closer"
require "notifier"
require "labeler"
require "project_manager"
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
    return if event_triggered_by_cp8?

    notify_new_pull_request
    notify_unwip
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

    def notify_recycle
      return unless payload.recycle_request?

      log "Notifying recycle request"
      notify RecycleNotification.new(issue: payload.issue, comment: payload.comment)
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
      return unless payload.opened_action?

      log "Moving new issues to project"
      ProjectManager.new(issue: payload.issue, project_column_id: config.project_column_id).run
    end

    def close_stale_issues
      log "Closing stale issues"
      IssueCloser.new(repo, weeks: config.stale_issue_weeks).run
    end

    def notify(notification)
      notifier.deliver(notification)
    end

    def notifier
      @_notifier ||= Notifier.new(channel: config.review_channel)
    end

    def event_triggered_by_cp8?
      current_user.id == payload.sender_id
    end

    def current_user
      github.user
    end

    def repo
      payload.repo
    end

    def github
      Cp8.github_client
    end
end
