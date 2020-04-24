class Authentication < ActiveRecord::Base
  belongs_to :user, inverse_of: :authentications

  validates :provider, presence: true,
                       uniqueness: { scope: :user_id },
                       unless: ->(auth) { auth.user_id.nil? }

  validates :uid, presence: true, uniqueness: { scope: :provider }

  before_destroy :check_not_last

  scope :having_provider, lambda {|provider|
    case provider
    when 'facebook', 'facebooknewflow'
      facebook = where('provider = ? OR provider = ?', 'facebook', 'facebooknewflow')
      return facebook if facebook.any?
    when 'google', 'googlenewflow'
      google = where('provider = ? OR provider = ?', 'google', 'googlenewflow')
      return google if google.any?
    else
      return where(provider: provider)
    end
  }

  def display_name
    case provider
    when 'identity' then 'Password'
    when 'google_oauth2' then 'Google'
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
