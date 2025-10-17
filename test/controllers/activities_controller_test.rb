require "test_helper"

class ActivitiesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @activity = activities(:one)
    @project = @activity.project
    @user = users(:one)
    sign_in @user
  end

  test "should get new with default due date" do
    travel_to Date.new(2025, 10, 16) do
      get new_project_activity_url(@project)
      assert_response :success
      assert_select 'input[name="activity[due_on]"][value="2025-10-17"]'
    end
  end

  test "should create activity" do
    assert_difference("Activity.count") do
      post project_activities_url(@project), params: {
        activity: {
          title: "New activity",
          description: "Some details",
          due_on: Date.current,
          category_id: categories(:two).id
        }
      }
    end

    assert_redirected_to project_url(@project)
  end

  test "should show activity" do
    get activity_url(@activity)
    assert_response :success
  end

  test "should get edit" do
    get edit_activity_url(@activity)
    assert_response :success
  end

  test "should update activity" do
    patch activity_url(@activity), params: { activity: { description: "Updated activity description", category_id: categories(:two).id } }
    assert_redirected_to activity_url(@activity)
    assert_equal "Updated activity description", @activity.reload.description
    assert_equal categories(:two), @activity.category
  end

  test "should destroy activity" do
    assert_difference("Activity.count", -1) do
      delete activity_url(@activity)
    end

    assert_redirected_to project_url(@project)
  end

  test "should toggle activity status" do
    patch toggle_done_activity_url(@activity)
    assert_redirected_to project_url(@project)
    assert @activity.reload.is_done
  end

  test "should redirect non owners trying to update activity" do
    sign_out @user
    sign_in users(:two)

    original_title = @activity.title
    patch activity_url(@activity), params: { activity: { title: "Hacked title" } }

    assert_redirected_to projects_url
    assert_equal original_title, @activity.reload.title
  end

  test "should redirect non owners trying to toggle activity" do
    sign_out @user
    sign_in users(:two)

    patch toggle_done_activity_url(@activity)

    assert_redirected_to projects_url
    refute @activity.reload.is_done
  end

  test "should redirect non owners trying to destroy activity" do
    sign_out @user
    sign_in users(:two)

    assert_no_difference("Activity.count") do
      delete activity_url(@activity)
    end

    assert_redirected_to projects_url
  end
end
