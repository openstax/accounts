class Authentication < ActiveRecord::Base
  attr_accessible :provider, :uid, :user_id

  belongs_to :user, inverse_of: :authentications

  validates :provider, presence: true
  validates :uid, presence: true, uniqueness: { scope: :provider }
end
