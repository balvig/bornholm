class Tags
  def initialize(new_title, previous_title)
    @new_title = new_title
    @previous_title = previous_title
  end

  def added
    return [] if previous_title.blank?

    new_title.tags - previous_title.tags
  end

  def removed
    return [] if previous_title.blank?

    previous_title.tags - new_title.tags
  end

  private

    attr_reader :new_title, :previous_title
end
