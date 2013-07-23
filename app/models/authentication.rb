class Authentication < ActiveRecord::Base
  attr_accessible :provider, :uid, :user_id

  belongs_to :user

  def self.find_with_omniauth(auth)
  	where{provider == auth['provider']}.where{uid == auth['uid']}.first
  end

  def self.create_with_omniauth(auth)
  	create(uid: auth['uid'], provider: auth['provider'])
  end
end
