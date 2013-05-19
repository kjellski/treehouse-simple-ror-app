require 'test_helper'

class UserFriendshipsControllerTest < ActionController::TestCase
  context "#index" do
    context "when not logged in" do
      should "redirect to the login page" do
        get :index
        assert_response :redirect
      end
    end

    context "when logged in" do
      setup do
        @friendship1 = create(:pending_user_friendship,
                                user: users(:kjellski),
                                friend: create(:user, first_name: 'Pending', last_name: 'Friend'))
        @friendship2 = create(:accepted_user_friendship,
                              user: users(:kjellski),
                              friend: create(:user, first_name: 'Active', last_name: 'Friend'))

        sign_in users(:kjellski)
        get :index
      end

      should "get the index page without error" do
        assert_response :success
      end

      should "assign user_friendships" do
        assert assigns(:user_friendships)
      end

      should "display friends names" do
        assert_match /Pending/, response.body
        assert_match /Active/, response.body
      end

      should "display pending information on a pending friendship" do
        assert_select "#user_friendship_#{@friendship1.id}" do
          assert_select "em", "Friendship is pending."
        end
      end

      should "display active information on a active friendship" do
        assert_select "#user_friendship_#{@friendship2.id}" do
          assert_select "em", "Friendship started at #{@friendship2.updated_at}."
        end
      end
    end
  end

  context "#new" do
    context "when not logged in" do
      should "redirect to the login page" do
        get :new
        assert_response :redirect
      end
    end

    context "when logged in" do
      setup do
        sign_in users(:kjellski)
      end

      should "successfully get the new ppage" do
        get :new
        assert_response :success
      end

      should "set a flash error if the friend_id params is missing" do
        get :new, {}
        assert_equal "Friend required", flash[:error]
      end

      should "display the friends name" do
        get :new, friend_id: users(:fred)
        assert_match /#{users(:fred).full_name}/, response.body
      end

      should "assign a new user friendship" do
        get :new, friend_id: users(:fred)
        assert assigns(:user_friendship)
      end

      should "assign a new user friendship to correct friend" do
        get :new, friend_id: users(:fred)
        assert_equal users(:fred), assigns(:user_friendship).friend
      end

      should "assign a new user friendship to the currently logged in user" do
        get :new, friend_id: users(:fred)
        assert_equal users(:kjellski), assigns(:user_friendship).user
      end

      should "returns a 404 if no friend is found" do
        get :new, friend_id: 'invalid'
        assert_response :not_found
      end

      should "ask if you really want to friend the user" do
        get :new, friend_id: users(:fred)
        assert_match /Do you really want to friend #{users(:fred).full_name}?/, response.body
      end
    end
  end

  context "#create" do
    context "whhen not logged in" do
      should "redirect to login when not logged in" do
        get :new
        assert_response :redirect
        assert_redirected_to login_path
      end
    end

    context "when logged in" do
      setup do
        sign_in users(:kjellski)
      end

      context "with no friend_id" do
        setup do
          post :create
        end

        should "set the flash error not empty" do
          assert !flash[:error].empty?
        end

        should "redirect to the site root" do
          assert_redirected_to root_path
        end
      end

      context "with valid friend_id" do
        setup do
          post :create, user_friendship: { friend_id: users(:fred) }
        end

        should "assign a friend object" do
          assert assigns(:friend)
          assert_equal users(:fred), assigns(:friend)
        end

        should "assign a user_friendship object" do
          assert assigns(:user_friendship)
          assert_equal users(:kjellski), assigns(:user_friendship).user
          assert_equal users(:fred), assigns(:user_friendship).friend
        end

        should "create a friendship" do
          assert users(:kjellski).pending_friends.include?(users(:fred))
        end

        should "redirect to the profile page of the friend" do
          assert_response :redirect
          assert_redirected_to profile_path(users(:fred))
        end

        should "set the flash success message" do
          assert flash[:success]
          assert_equal "You are now friends with #{users(:fred).full_name}", flash[:success]
        end
      end
    end
  end
end