class Status < ActiveRecord::Base
  attr_accessible :content, :user_id

  validates :user, presence: true

  belongs_to :user
end
