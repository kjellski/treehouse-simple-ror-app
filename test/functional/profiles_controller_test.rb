require 'test_helper'

class ProfilesControllerTest < ActionController::TestCase
  test "should get show" do
    get :show, id: users(:kjellski).profile_name

    assert_template 'profiles/show'
    assert_response :success
  end

  test "should render a 404 on profile not found" do
    get :show, id: "doesn't exist"
    assert_response :not_found
  end

  test "that variables are assigned on successful profile viewing" do
    get :show, id: users(:kjellski).profile_name

    assert assigns(:user)
    assert_not_empty assigns(:statuses)
  end

  test "only shows the users own statuses" do
    get :show, id: users(:kjellski).profile_name

    assigns(:statuses).each do |status|
      assert_equal users(:kjellski), status.user
    end
  end

end
