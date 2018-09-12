require "test_helper"

class LabelTest < Minitest::Test
  def test_detecting_prefix
    label = Label.new("move-to: elsewhere")

    assert_equal "move-to", label.prefix
  end

  def test_detecting_suffix
    label = Label.new("move-to: elsewhere")

    assert_equal "elsewhere", label.suffix
  end

  def test_detecting_suffix_with_extra_space
    label = Label.new("move-to: elsewhere  ")

    assert_equal "elsewhere", label.suffix
  end
end
