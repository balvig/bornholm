class Configuration
  attr_reader :stale_issue_weeks, :review_channel, :move_to_prefix

  def initialize(stale_issue_weeks: nil, review_channel: nil, move_to_prefix: nil)
    @stale_issue_weeks = stale_issue_weeks
    @review_channel = review_channel
    @move_to_prefix = move_to_prefix
  end
end
