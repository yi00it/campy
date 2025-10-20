require "test_helper"

class ActivityTest < ActiveSupport::TestCase
  # Create our own test data instead of relying on fixtures
  self.use_transactional_tests = true

  setup do
    # Create a user and project for testing without relying on fixtures
    @user = User.create!(
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    @project = @user.projects.create!(
      name: "Test Project",
      description: "Test description"
    )
  end

  test "defaults due_on to tomorrow for new records" do
    travel_to Date.new(2025, 10, 16) do
      activity = Activity.new
      assert_equal Date.new(2025, 10, 17), activity.due_on
    end
  end

  # Duration calculation tests
  test "calculates due_on from duration_days correctly for 1 day" do
    activity = @project.activities.build(
      title: "One day task",
      start_on: Date.new(2025, 10, 20),
      duration_days: 1
    )
    activity.valid?
    assert_equal Date.new(2025, 10, 20), activity.due_on, "1-day task should end on same day"
  end

  test "calculates due_on from duration_days correctly for 5 days" do
    activity = @project.activities.build(
      title: "Five day task",
      start_on: Date.new(2025, 10, 20),
      duration_days: 5
    )
    activity.valid?
    assert_equal Date.new(2025, 10, 24), activity.due_on, "5-day task starting Monday should end Friday"
  end

  test "calculates due_on from duration_days correctly for 10 days" do
    activity = @project.activities.build(
      title: "Ten day task",
      start_on: Date.new(2025, 10, 1),
      duration_days: 10
    )
    activity.valid?
    assert_equal Date.new(2025, 10, 10), activity.due_on, "10-day task should span exactly 10 days"
  end

  test "does not calculate due_on when duration_days is nil" do
    activity = @project.activities.build(
      title: "Manual dates",
      start_on: Date.new(2025, 10, 20),
      due_on: Date.new(2025, 10, 30)
    )
    activity.valid?
    assert_equal Date.new(2025, 10, 30), activity.due_on, "Manual due_on should be preserved"
  end

  test "recalculates due_on when duration_days changes" do
    activity = @project.activities.create!(
      title: "Task with changing duration",
      start_on: Date.new(2025, 10, 20),
      duration_days: 5
    )
    assert_equal Date.new(2025, 10, 24), activity.due_on

    activity.update(duration_days: 10)
    assert_equal Date.new(2025, 10, 29), activity.due_on, "due_on should update when duration changes"
  end

  test "recalculates due_on when start_on changes" do
    activity = @project.activities.create!(
      title: "Task with changing start",
      start_on: Date.new(2025, 10, 20),
      duration_days: 5
    )
    assert_equal Date.new(2025, 10, 24), activity.due_on

    activity.update(start_on: Date.new(2025, 10, 21))
    assert_equal Date.new(2025, 10, 25), activity.due_on, "due_on should update when start_on changes"
  end

  test "validates due_on is not before start_on" do
    activity = @project.activities.build(
      title: "Invalid dates",
      start_on: Date.new(2025, 10, 20),
      due_on: Date.new(2025, 10, 15)
    )
    assert_not activity.valid?
    assert_includes activity.errors[:due_on], "cannot be before the start date"
  end

  test "validates duration_days is greater than zero" do
    activity = @project.activities.build(
      title: "Invalid duration",
      start_on: Date.new(2025, 10, 20),
      duration_days: 0
    )
    assert_not activity.valid?
    assert_includes activity.errors[:duration_days], "must be greater than 0"
  end

  test "validates duration_days is a number" do
    activity = @project.activities.build(
      title: "Invalid duration",
      start_on: Date.new(2025, 10, 20),
      duration_days: "invalid"
    )
    assert_not activity.valid?
    assert_includes activity.errors[:duration_days], "is not a number"
  end
end
