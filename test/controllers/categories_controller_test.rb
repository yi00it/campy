require "test_helper"

class CategoriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in @user
    @category = categories(:one)
  end

  test "should get index" do
    get categories_url
    assert_response :success
  end

  test "should create category" do
    assert_difference("Category.count") do
      post categories_url, params: { category: { name: "Review" } }
    end

    assert_redirected_to categories_url
  end

  test "should update category" do
    patch category_url(@category), params: { category: { name: "Updated" } }
    assert_redirected_to categories_url
    assert_equal "Updated", @category.reload.name
  end

  test "should destroy empty category" do
    empty_category = Category.create!(name: "Temporary")

    assert_difference("Category.count", -1) do
      delete category_url(empty_category)
    end

    assert_redirected_to categories_url
  end

  test "should not destroy category with activities" do
    assert_no_difference("Category.count") do
      delete category_url(@category)
    end

    assert_redirected_to categories_url
    assert_match "Cannot delete", flash[:alert]
  end
end
