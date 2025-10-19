require "test_helper"

class DisciplinesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in @user
    @discipline = Discipline.create!(name: "Structure")
  end

  test "should get index" do
    get disciplines_url
    assert_response :success
  end

  test "should create discipline" do
    assert_difference("Discipline.count") do
      post disciplines_url, params: { discipline: { name: "MEP" } }
    end
  end

  test "should update discipline" do
    patch discipline_url(@discipline), params: { discipline: { name: "Finishes" } }
    assert_redirected_to disciplines_url
    assert_equal "Finishes", @discipline.reload.name
  end

  test "should destroy discipline" do
    empty = Discipline.create!(name: "Temporary")
    assert_difference("Discipline.count", -1) do
      delete discipline_url(empty)
    end
  end
end
