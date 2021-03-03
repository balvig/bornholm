require "active_support/core_ext/hash"
require "json"
require "comment"
require "issue"
require "review"
require "tags"

class Payload
  def self.new_from_json(raw_json)
    new JSON.parse(raw_json)
  end

  def initialize(data = {})
    @data = data.deep_symbolize_keys
  end

  def issue
    @_issue ||= Issue.new(**issue_params)
  end

  def review
    return if review_params.blank?
    @_review ||= Review.new(**review_params)
  end

  def repo
    data[:repository][:full_name]
  end

  def sender_bot?
    sender.bot?
  end

  def blocker_action?
    tags.added.include?(:blocker)
  end

  def recycle_request?
    added_recycle_comment? || dismissed_review?
  end

  def review_action?
    action.submitted? && review
  end

  def submitter_action?
    issue.user == sender
  end

  def opened_new_issue?
    action.opened? && issue_action?
  end

  def issue_action?
    !pull_request_action?
  end

  def pull_request_action?
    data[:pull_request].present?
  end

  def action
    ActiveSupport::StringInquirer.new(data[:action])
  end

  def label
    Label.new(data[:label][:name])
  end

  def comment
    return unless comment_params

    Comment.new(**comment_params)
  end

  def installation_id
    data[:installation][:id]
  end

  private

    attr_reader :data

    def issue_params
      issue_or_pull_request_data.merge(repo: repo)
    end

    def comment_params
      data[:comment]
    end

    def review_params
      data[:review]
    end

    def issue_or_pull_request_data
      data[:issue] || data[:pull_request]
    end

    def tags
      Tags.new(issue.title, previous_title)
    end

    def previous_title
      IssueTitle.new(data.fetch(:changes, {}).fetch(:title, {}).fetch(:from, {}) || "")
    end

    def added_recycle_comment?
      action.created? && comment&.recycle_request?
    end

    def dismissed_review?
      action == "dismissed"
    end

    def sender
      User.new(**data[:sender])
    end
end
