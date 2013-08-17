class Authentication < ActiveRecord::Base
  attr_accessible :provider, :uid, :user_id

  belongs_to :user

  def self.find(provider, uid)
    where{provider == provider}.where{uid == uid}.first
  end

  def self.find!(provider, uid)
    find(provider, uid) || create(uid: uid, provider: provider)
  end
end
