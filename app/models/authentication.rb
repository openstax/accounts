class Authentication < ApplicationRecord
  belongs_to :user, inverse_of: :authentications

  validates :provider, presence: true,
                       uniqueness: { scope: :user_id },
                       unless: ->(auth) { auth.user_id.nil? }

  validates :uid, presence: true, uniqueness: { scope: :provider }

  before_destroy :check_not_last

  def display_name
    case provider
    when 'identity' then 'Password'
    else provider.capitalize
    end
  end

  protected

  def check_not_last
    if user.present? && user.authentications.size <= 1 && user.activated?
      throw(:abort)
    end
  end
end
