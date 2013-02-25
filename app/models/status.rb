class Status < ActiveRecord::Base
  attr_accessible :content, :user_id

  validates :user_id, presence: true
  validates :content, presence: true,
            length: { minimum: 2}

  belongs_to :user
end
