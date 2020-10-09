class IssueTitle < SimpleDelegator
  VALID_TAGS = {
    "Blocker" => :blocker
  }

  ESCAPED_CHARACTERS = {
    "<" => "&lt;",
    ">" => "&gt;",
    "&" => "&amp;"
  }.freeze

  def tags
    raw_tags.map do |tag|
      VALID_TAGS[tag]
    end.compact
  end

  def to_s
    self.gsub(/[#{ESCAPED_CHARACTERS.keys.join}]/, ESCAPED_CHARACTERS)
  end

  private

    def raw_tags
      scan(/\[(\w+)\]/).flatten
    end
end
