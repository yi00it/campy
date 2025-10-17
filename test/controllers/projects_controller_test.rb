require "test_helper"

class ProjectsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @project = projects(:one)
    sign_in @user
  end

  test "should get index" do
    get projects_url
    assert_response :success
  end

  test "should get new" do
    get new_project_url
    assert_response :success
  end

  test "should create project" do
    assert_difference("Project.count") do
      post projects_url, params: { project: { description: "New project description", name: "New Project" } }
    end

    assert_redirected_to project_url(Project.last)
  end

  test "should show project" do
    get project_url(@project)
    assert_response :success
  end

  test "should get edit" do
    get edit_project_url(@project)
    assert_response :success
  end

  test "should update project" do
    patch project_url(@project), params: { project: { description: "Updated description" } }
    assert_redirected_to project_url(@project)
    assert_equal "Updated description", @project.reload.description
  end

  test "should destroy project" do
    assert_difference("Project.count", -1) do
      delete project_url(@project)
    end

    assert_redirected_to projects_url
  end

  test "should redirect non owners trying to update project" do
    sign_out @user
    sign_in users(:two)

    original_name = @project.name
    patch project_url(@project), params: { project: { name: "Hacked name" } }

    assert_redirected_to projects_url
    assert_equal original_name, @project.reload.name
  end

  test "should redirect non owners trying to destroy project" do
    sign_out @user
    sign_in users(:two)

    assert_no_difference("Project.count") do
      delete project_url(@project)
    end

    assert_redirected_to projects_url
  end
end
