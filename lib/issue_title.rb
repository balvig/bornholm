class IssueTitle < SimpleDelegator
  VALID_TAGS = {
    "WIP" => :wip,
    "Blocker" => :blocker
  }

  def tags
    raw_tags.map do |tag|
      VALID_TAGS[tag]
    end.compact
  end

  private

    def raw_tags
      scan(/\[(\w+)\]/).flatten
    end
end
