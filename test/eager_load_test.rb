require 'test_helper'

# Production loads every class at boot; development and tests load them on
# first use. A class that only loads in the second way would stop production
# from starting (SpectrePaginationRenderer did, 2026-10-23).
class EagerLoadTest < ActiveSupport::TestCase
  test "every class loads as production loads it" do
    assert_nothing_raised { Rails.application.eager_load! }
  end
end
