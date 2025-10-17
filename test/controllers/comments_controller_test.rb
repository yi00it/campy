require "test_helper"

class CommentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @activity = activities(:one)
    @comment = comments(:one)
    sign_in @user
  end

  test "should create comment for own activity" do
    assert_difference("Comment.count") do
      post activity_comments_url(@activity), params: { comment: { body: "Nice work!" } }
    end

    assert_redirected_to activity_url(@activity)
  end

  test "should destroy comment for own activity" do
    activity = @comment.activity
    assert_difference("Comment.count", -1) do
      delete comment_url(@comment)
    end

    assert_redirected_to activity_url(activity)
  end

  test "should redirect non owners trying to add comment" do
    sign_out @user
    sign_in users(:two)

    assert_no_difference("Comment.count") do
      post activity_comments_url(@activity), params: { comment: { body: "Unauthorized" } }
    end

    assert_redirected_to projects_url
  end

  test "should redirect non owners trying to delete comment" do
    sign_out @user
    sign_in users(:two)

    assert_no_difference("Comment.count") do
      delete comment_url(@comment)
    end

    assert_redirected_to projects_url
  end
end
