require "test_helper"

class IssueTitleTest < Minitest::Test
  def test_tags
    title = IssueTitle.new("[WIP] Still working on it")

    assert_equal [:wip], title.tags
  end
end
