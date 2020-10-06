require "label"

class Labeler
  def initialize(issue)
    @issue = issue
  end

  def run
    if open?
      remove_label(:Icebox)
    end
  end

  private

    attr_reader :issue

    def repo
      issue.repo
    end

    def open?
      !issue.closed?
    end

    def add_label(label)
      Label.new(label).add_to(issue)
    end

    def remove_label(label)
      Label.new(label).remove_from(issue)
    end
end
