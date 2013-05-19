require 'test_helper'

class UserFriendshipTest < ActiveSupport::TestCase
  should belong_to(:user)
  should belong_to(:friend)

  test "that creating a friendship works without raising an exception" do
    assert_nothing_raised do
      UserFriendship.create user: users(:kjellski), friend: users(:fred)
    end
  end

  test "that creating a friendship based on user id and friend id works" do
    UserFriendship.create user_id: users(:kjellski).id, friend_id: users(:fred).id
    assert users(:kjellski).pending_friends.include?(users(:fred))
  end

  context "a new instance" do
    setup do
      @user_friendship = UserFriendship.new user: users(:kjellski), friend: users(:anna)
    end

    should "have a pending state" do
      assert_equal 'pending', @user_friendship.state
    end
  end

  context "#send_request_email" do
    setup do
      @user_friendship = UserFriendship.create user: users(:kjellski), friend: users(:fred)
    end

    should "send an email" do
      assert_difference 'ActionMailer::Base.deliveries.size', 1 do
        @user_friendship.send_request_email
      end
    end
  end

  context "#mutual friendship" do
    setup do
      UserFriendship.request users(:kjellski), users(:fred)
      @friendship1 = users(:kjellski).user_friendships.where(friend_id: users(:fred).id).first
      @friendship2 = users(:fred).user_friendships.where(friend_id: users(:kjellski).id).first
    end

    should "correctly find mutual friendship" do
      assert_equal @friendship2, @friendship1.mutual_friendship
      assert_equal @friendship1, @friendship2.mutual_friendship
    end
  end

  context "#accept_mutual_friendship!" do
    setup do
      UserFriendship.request users(:kjellski), users(:fred)
    end

    should "accept mutual friendship" do
      friendship1 = users(:kjellski).user_friendships.where(friend_id: users(:fred).id).first
      friendship2 = users(:fred).user_friendships.where(friend_id: users(:kjellski).id).first

      friendship1.accept_mutual_friendship!
      friendship2.reload

      assert_equal 'accepted', friendship2.state
    end
  end

  context "#accept!" do
    setup do
      @user_friendship = UserFriendship.request(users(:kjellski), users(:fred))
    end

    should "set the state to be accepted" do
      @user_friendship.accept!
      assert_equal "accepted", @user_friendship.state
    end

    should "send an acceptance email" do
      assert_difference 'ActionMailer::Base.deliveries.size', 1 do
        @user_friendship.accept!
      end
    end

    should "include the friend in the list of friends" do
      @user_friendship.accept!
      users(:kjellski).friends.reload
      assert users(:kjellski).friends.include?(users(:fred))
    end

    should "accept the mutual friendship" do
      @user_friendship.accept!
      assert_equal 'accepted', @user_friendship.mutual_friendship.state
    end
  end

  context ".request" do
    should "create two user friendships" do
      assert_difference 'UserFriendship.count', 2 do
        UserFriendship.request(users(:kjellski), users(:fred))
      end
    end

    should "send a friend request email" do
      assert_difference 'ActionMailer::Base.deliveries.count', 1 do
        UserFriendship.request(users(:kjellski), users(:fred))
      end
    end
  end

  context "#delete_mutual_friendship!" do
    setup do
      UserFriendship.request users(:kjellski), users(:fred)
      @friendship1 = users(:kjellski).user_friendships.where(friend_id: users(:fred).id).first
      @friendship2 = users(:fred).user_friendships.where(friend_id: users(:kjellski).id).first
    end

    should "delete mutual friendship" do
      assert_equal @friendship1, @friendship2.mutual_friendship
      @friendship1.delete_mutual_friendship!
      assert !UserFriendship.exists?(@friendship2)
    end
  end

  context "#destroy" do
    setup do
      UserFriendship.request users(:kjellski), users(:fred)
      @friendship1 = users(:kjellski).user_friendships.where(friend_id: users(:fred).id).first
      @friendship2 = users(:fred).user_friendships.where(friend_id: users(:kjellski).id).first
    end

    should "delete mutual friendship" do
      @friendship1.destroy
      assert !UserFriendship.exists?(@friendship2)
    end
  end
end

