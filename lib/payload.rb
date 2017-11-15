require "json"
require "issue"

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

  def repo
    data[:repository][:full_name]
  end

  def sender_id
    data[:sender][:id]
  end

  def pull_request?
    data[:pull_request].present?
  end

  def action
    data[:action]
  end

  private

    attr_reader :data

    def issue_params
      issue_or_pull_request_data.merge(repo: repo)
    end

    def issue_or_pull_request_data
      data[:issue] || data[:pull_request]
    end
end
