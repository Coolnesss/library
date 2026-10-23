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

  test "the thought of the day is in the page's language, when there is one" do
    Rails.cache.clear
    sindhi = Thought.create!(content: 'ڪتاب', rtl: true)

    assert_equal sindhi, Thought.daily_thought(rtl: true)
    assert_equal thoughts(:english), Thought.daily_thought(rtl: false)

    sindhi.destroy
    Rails.cache.clear
    assert_equal thoughts(:english), Thought.daily_thought(rtl: true)
  end
end
