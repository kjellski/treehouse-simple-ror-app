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
        @friendship3 = create(:requested_user_friendship,
                              user: users(:kjellski),
                              friend: create(:user, first_name: 'Requested', last_name: 'Friend'))
        @friendship4 = user_friendships(:blocked_by_kjellski)

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
          assert_select "em", "Friendship is pending"
        end
      end

      should "display date information on a accepted friendship" do
        assert_select "#user_friendship_#{@friendship2.id}" do
          assert_select "em", "Friendship is accepted"
        end
      end

      context "blocked friendships" do
        setup do
          get :index, list: 'blocked'
        end

        should "get the index without error" do
          assert_response :success
        end

        should "not display pending or active friends names" do
          assert_no_match /Penging\ Friend/, response.body
          assert_no_match /Active\ Friend/, response.body
        end

        should "display blocked users names" do
          assert_match /Blocked\ Friend/, response.body
        end
      end

      context "pending friendships" do
        setup do
          get :index, list: 'pending'
        end

        should "get the index without error" do
          assert_response :success
        end

        should "not display pending or active friends names" do
          assert_no_match /Blocked\ Friend/, response.body
          assert_no_match /Active\ Friend/, response.body
        end

        should "display blocked users names" do
          assert_match /Pending\ Friend/, response.body
        end
      end

      context "requested friendships" do
        setup do
          get :index, list: 'requested'
        end

        should "get the index without error" do
          assert_response :success
        end

        should "not display pending or active friends names" do
          assert_no_match /Active\ Friend/, response.body
          assert_no_match /Blocked\ Friend/, response.body
        end

        should "display blocked users names" do
          assert_match /Requested\ Friend/, response.body
        end
      end

      context "accepted friendships" do
        setup do
          get :index, list: 'accepted'
        end

        should "get the index without error" do
          assert_response :success
        end

        should "not display pending or blocked friends names" do
          assert_no_match /Pending\ Friend/, response.body
          assert_no_match /Requested\ Friend/, response.body
        end

        should "display accepted users names" do
          assert_match /Active\ Friend/, response.body
        end
      end
    end
  end


  context "#edit" do
    context "when not logged in" do
      should "redirect to the login page" do
        get :edit, id: 1
        assert_response :redirect
      end
    end

    context "when logged in and get edit" do
      setup do
        @user_friendship = create(:pending_user_friendship, user: users(:kjellski))
        sign_in users(:kjellski)
        get :edit, id: @user_friendship.friend.profile_name
      end

      should "return success" do
        assert_response :success
      end

      should "assign to user_friendship" do
        assert assigns(:user_friendship)
      end

      should "assign to friend" do
        assert assigns(:friend)
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

      should "successfully get the new page" do
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
    context "when not logged in" do
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

      context "sucessfully" do
        should "create two user friendship objects" do
          assert_difference 'UserFriendship.count', 2 do
            post :create, user_friendship: { friend_id: users(:fred).profile_name }
          end
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
          assert_equal "Friend request was sent.", flash[:success]
        end
      end
    end
  end

  context "#accept" do
    context "when not logged in" do
      should "redirect to login when not logged in" do
        put :accept, id: 1
        assert_response :redirect
        assert_redirected_to login_path
      end
    end

    context "when logged in" do
      setup do
        @friend = create(:user)
        @user_friendship = create(:pending_user_friendship, friend: @friend, user: users(:kjellski))
        create(:pending_user_friendship, friend: users(:kjellski), user: @friend)
        sign_in users(:kjellski)
        put :accept, id: @user_friendship
        @user_friendship.reload
      end

      should "assign a user friendship" do
        assert assigns(:user_friendship)
        assert_equal @user_friendship, assigns(:user_friendship)
      end

      should "update the state to accepted" do
        assert_equal 'accepted', @user_friendship.state
      end

      should "have a flash message success" do
        assert_equal "You are now friends with #{@user_friendship.friend.first_name}.", flash[:success]
      end
    end
  end

  context "#destroy" do
    context "when not logged in" do
      should "redirect to login when not logged in" do
        delete :destroy, id: 1
        assert_response :redirect
        assert_redirected_to login_path
      end
    end

    context "when logged in" do
      setup do
        @friend = create(:user)
        @user_friendship = create(:accepted_user_friendship, friend: @friend, user: users(:kjellski))
        create(:accepted_user_friendship, friend: users(:kjellski), user: @friend)

        sign_in users(:kjellski)
      end

      should "delete user friendship" do
        assert_difference 'UserFriendship.count', -2 do
          delete :destroy, id: @user_friendship
        end
      end

      should "set the flash message" do
        delete :destroy, id: @user_friendship
        assert_equal "Friendship destroyed.", flash[:success]
      end
    end
  end

  context "#block" do
    context "when not logged in" do
      should "redirect to login when not logged in" do
        put :block, id: 1
        assert_response :redirect
        assert_redirected_to login_path
      end
    end

    context "when logged in" do
      setup do
        @user_friendship = create(:pending_user_friendship, user: users(:kjellski))
        sign_in users(:kjellski)
        put :block, id: @user_friendship
        @user_friendship.reload
      end

      should "assign a user friendship" do
        assert assigns(:user_friendship)
        assert_equal @user_friendship, assigns(:user_friendship)
      end

      should "update the user friendship state to blocked" do
        assert_equal 'blocked', @user_friendship.state
      end
    end
  end
end