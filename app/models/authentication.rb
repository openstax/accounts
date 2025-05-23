include UserSessionManagement

class Authentication < ApplicationRecord
  belongs_to :user, inverse_of: :authentications, optional: true

  validates :provider, presence: true,
                       uniqueness: { scope: :user_id },
                       unless: ->(auth) { auth.user_id.nil? }

  validates :uid, presence: true, uniqueness: { scope: :provider }

  before_destroy :check_not_last

  def display_name
    case provider
    when 'identity' then 'Password'
    when 'google_oauth2' then 'Google'
    else provider.capitalize
    end
  end

  protected

  def check_not_last
    return if user.nil? || user.is_deleted?

    if user.present? && user.authentications.size <= 1 && user.activated?
      throw(:abort)
    end
  end
end
