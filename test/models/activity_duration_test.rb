require "test_helper"

class ActivityDurationTest < ActiveSupport::TestCase
  # Test duration calculation logic specifically
  # These tests create their own data to avoid fixture dependency issues

  def setup
    # Clean slate: create test data programmatically
    @user = User.find_or_create_by!(email: "duration_test@example.com") do |u|
      u.password = "password123"
      u.password_confirmation = "password123"
    end

    @project = @user.projects.find_or_create_by!(name: "Duration Test Project") do |p|
      p.description = "Test project for duration calculations"
    end
  end

  test "1-day task: start and due on same day" do
    activity = @project.activities.build(
      title: "One day task",
      start_on: Date.new(2025, 10, 20),  # Monday
      duration_days: 1
    )
    activity.valid?
    assert_equal Date.new(2025, 10, 20), activity.due_on,
      "1-day task should end on same day (Monday = Monday)"
  end

  test "5-day task: Monday to Friday" do
    activity = @project.activities.build(
      title: "Five day task",
      start_on: Date.new(2025, 10, 20),  # Monday
      duration_days: 5
    )
    activity.valid?
    assert_equal Date.new(2025, 10, 24), activity.due_on,
      "5-day task starting Monday should end Friday (Oct 20 + 4 days = Oct 24)"
  end

  test "10-day task spans exactly 10 days" do
    activity = @project.activities.build(
      title: "Ten day task",
      start_on: Date.new(2025, 10, 1),
      duration_days: 10
    )
    activity.valid?
    assert_equal Date.new(2025, 10, 10), activity.due_on,
      "10-day task should span exactly 10 days (Oct 1 to Oct 10)"
  end

  test "manual due date is preserved when duration_days is nil" do
    activity = @project.activities.build(
      title: "Manual dates",
      start_on: Date.new(2025, 10, 20),
      due_on: Date.new(2025, 10, 30)
    )
    activity.valid?
    assert_equal Date.new(2025, 10, 30), activity.due_on,
      "Manual due_on should be preserved when duration_days is nil"
  end

  test "updating duration_days recalculates due_on" do
    activity = @project.activities.create!(
      title: "Task with changing duration",
      start_on: Date.new(2025, 10, 20),
      duration_days: 5
    )
    assert_equal Date.new(2025, 10, 24), activity.due_on

    activity.update(duration_days: 10)
    assert_equal Date.new(2025, 10, 29), activity.due_on,
      "due_on should recalculate when duration changes (20 + 9 days = 29)"
  end

  test "updating start_on recalculates due_on" do
    activity = @project.activities.create!(
      title: "Task with changing start",
      start_on: Date.new(2025, 10, 20),
      duration_days: 5
    )
    assert_equal Date.new(2025, 10, 24), activity.due_on

    activity.update(start_on: Date.new(2025, 10, 21))
    assert_equal Date.new(2025, 10, 25), activity.due_on,
      "due_on should recalculate when start_on changes (21 + 4 days = 25)"
  end

  test "validates due_on cannot be before start_on" do
    activity = @project.activities.build(
      title: "Invalid dates",
      start_on: Date.new(2025, 10, 20),
      due_on: Date.new(2025, 10, 15)
    )
    assert_not activity.valid?
    assert_includes activity.errors[:due_on], "cannot be before the start date"
  end

  test "validates duration_days must be greater than zero" do
    activity = @project.activities.build(
      title: "Invalid duration",
      start_on: Date.new(2025, 10, 20),
      duration_days: 0
    )
    assert_not activity.valid?
    assert_includes activity.errors[:duration_days], "must be greater than 0"
  end

  test "validates duration_days must be a number" do
    activity = @project.activities.build(
      title: "Invalid duration",
      start_on: Date.new(2025, 10, 20),
      duration_days: "not_a_number"
    )
    assert_not activity.valid?
    assert_includes activity.errors[:duration_days], "is not a number"
  end

  test "negative duration_days is invalid" do
    activity = @project.activities.build(
      title: "Negative duration",
      start_on: Date.new(2025, 10, 20),
      duration_days: -5
    )
    assert_not activity.valid?
    assert_includes activity.errors[:duration_days], "must be greater than 0"
  end
end
