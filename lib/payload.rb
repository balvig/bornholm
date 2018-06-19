require "active_support/core_ext/hash"
require "json"
require "comment"
require "issue"
require "review"

class Payload
  def self.new_from_json(raw_json)
    new JSON.parse(raw_json)
  end

  def initialize(data = {})
    @data = data.deep_symbolize_keys
  end

  def issue
    @_issue ||= Issue.new(issue_params)
  end

  def review
    return if review_params.blank?
    @_review ||= Review.new(review_params)
  end

  def repo
    data[:repository][:full_name]
  end

  def sender_id
    data[:sender][:id]
  end

  def unwip_action?
    action.edited? && !issue.wip? && previous_title.include?(Issue::WIP_TAG)
  end

  def recycle_request?
    action.created? && comment&.recycle_request?
  end

  def review_action?
    action.submitted? && review&.decisive?
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

  def comment
    return unless comment_params

    Comment.new(comment_params)
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

    def previous_title
      data.fetch(:changes, {}).fetch(:title, {}).fetch(:from, {}) || ""
    end
end
