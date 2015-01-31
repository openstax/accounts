class Authentication < ActiveRecord::Base
  attr_accessible :provider, :uid, :user_id

  belongs_to :user, inverse_of: :authentications

  validates_uniqueness_of :uid, scope: :provider
end
