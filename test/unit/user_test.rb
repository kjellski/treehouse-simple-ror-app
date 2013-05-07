require 'test_helper'

class UserTest < ActiveSupport::TestCase

  should have_many(:user_friendships)
  should have_many(:friends)

  test "a user should enter a first name" do
    user = User.new
    assert !user.save
    assert !user.errors[:first_name].empty?
  end

  test "a user should enter a last name" do
    user = User.new
    assert !user.save
    assert !user.errors[:last_name].empty?
  end

  test "a user should enter a profile name" do
    user = User.new
    assert !user.save
    assert !user.errors[:profile_name].empty?
  end

  test "a users profile name should be unique" do
    user = User.new
    user.profile_name = users(:kjellski).profile_name

    assert !user.save
    assert !user.errors[:profile_name].empty?
  end

  test "a user should have a profile name without spaces" do
    user = User.new(first_name: 'kjellski', last_name: 'otto', email: 'otto.kjell@aslaksd.com')
    user.password = user.password_confirmation = 'asdfasdf'

    user.profile_name = "This is a wrong profile name"

    assert !user.save
    assert !user.errors[:profile_name].empty?
    assert user.errors[:profile_name].include?("Must be formatted correctly.")
  end

  test "a user can have a correctly formatted profile name" do
    user = User.new(first_name: 'kjellski', last_name: 'otto', email: 'otto.kjell@aslaksd.com')
    user.password = user.password_confirmation = 'asdfasdf'
    user.profile_name = 'kjellski1'

    assert user.valid?
  end

  test "that no error is raised when trying to access friend list" do
    assert_nothing_raised do
      users(:kjellski).friends
    end
  end

  test "that creating friendships on a user works" do
    users(:kjellski).friends << users(:fred)
    users(:kjellski).friends.reload
    assert users(:kjellski).friends.include?(users(:fred))
  end
end
