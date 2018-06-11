class Configuration
  attr_reader :stale_issue_weeks, :review_channel, :project_column_id

  def initialize(stale_issue_weeks: nil, review_channel: nil, project_column_id: nil)
    @stale_issue_weeks = stale_issue_weeks
    @review_channel = review_channel
    @project_column_id = project_column_id
  end
end
