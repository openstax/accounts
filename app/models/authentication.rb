class Authentication < ActiveRecord::Base
  attr_accessible :provider, :uid, :user_id

  belongs_to :user

  def self.by_provider_and_uid(provider, uid)
    where(provider: provider).where(uid: uid.to_s).first
  end

  def self.by_provider_and_uid!(provider, uid)
    by_provider_and_uid(provider, uid) || create(uid: uid.to_s, provider: provider)
  end
end
