require "test_helper"

class BuddyMentionTest < Minitest::Test
  def setup
    BuddyResolver.mappings = [["Knack", "balvig"]]
  end

  def test_buddy_mapping
    user = User.new(login: "Knack")
    assert_equal "balvig", BuddyResolver.new(user).buddy.login
  end

  def test_inverse_buddy_mapping
    user = User.new(login: "balvig")
    assert_equal "knack", BuddyResolver.new(user).buddy.login
  end

  def test_no_buddy_mapping
    user = User.new(login: "bob")
    assert_nil BuddyResolver.new(user).buddy
  end
end
