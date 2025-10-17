require "test_helper"

class ActivityTest < ActiveSupport::TestCase
  test "defaults due_on to tomorrow for new records" do
    travel_to Date.new(2025, 10, 16) do
      activity = Activity.new
      assert_equal Date.new(2025, 10, 17), activity.due_on
    end
  end

  test "does not override existing due_on values" do
    activity = activities(:one)
    assert_equal Date.parse("2025-10-16"), activity.due_on
  end
end
