require "test_helper"

class ZonesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in @user
    @zone = Zone.create!(name: "Lobby")
  end

  test "should get index" do
    get zones_url
    assert_response :success
  end

  test "should create zone" do
    assert_difference("Zone.count") do
      post zones_url, params: { zone: { name: "Guest Rooms" } }
    end
  end

  test "should update zone" do
    patch zone_url(@zone), params: { zone: { name: "Service Core" } }
    assert_redirected_to zones_url
    assert_equal "Service Core", @zone.reload.name
  end

  test "should destroy zone" do
    empty = Zone.create!(name: "Temporary")
    assert_difference("Zone.count", -1) do
      delete zone_url(empty)
    end
  end
end
