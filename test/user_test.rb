require "test_helper"

class UserTest < Minitest::Test
  def test_uniq_filtering_based_on_login
    users = [
      User.new(login: "single"),
      User.new(login: "dupe"),
      User.new(login: "dupe")
    ]

    result = users.uniq

    assert_equal %w(single dupe), result.map(&:login)
  end

  def test_no_mapping_for_chat_name
    user = User.new(login: "balvig")
    assert_equal "<@balvig>", user.chat_name
  end

  def test_chat_name_github_to_slack_mapping
    user = User.new(login: "firewalker06")
    assert_equal "<@U02JXH8J4>", user.chat_name
  end
end
