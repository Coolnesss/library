require 'test_helper'

class ThoughtTest < ActiveSupport::TestCase
  test "right-to-left thoughts use the Sindhi font" do
    thought = Thought.new(rtl: true)
    assert_equal 'rtl', thought.direction_html
    assert_equal 'sindhi', thought.html_class

    thought.rtl = false
    assert_equal 'ltr', thought.direction_html
    assert_equal '', thought.html_class
  end
end
