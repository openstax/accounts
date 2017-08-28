class SignupState < ActiveRecord::Base
  attr_accessible :contact_info_value, :role, :return_to, :trusted_data, :verified

  enum contact_info_kind: [:email_address]

  before_validation :prepare
  before_create :initialize_tokens

  include EmailAddressValidations

  email_validation_formats.each do |format|
    validates :contact_info_value, format: format, if: -> { email_address? }
  end

  validates :contact_info_kind, presence: true
  validates :contact_info_value, presence: true

  scope :verified, -> { where(verified: true) }
  sifter :verified do verified.eq true end

  def self.create_from_trusted_data(data)
    role = User.roles[data[:role]] ? data[:role] : nil
    SignupState.create!(
      role: role,
      verified: true,
      contact_info_value: data[:email],
      trusted_data: {
        email: data[:email],
        name:  data[:name],
        uuid:  data[:external_user_uuid],
        role:  role
      }
    )
  end

  def trusted?
    trusted_data.present?
  end

  def after_email_action
    return :verify_email unless trusted?
    if role == 'instructor'
      :password
    else
      :trusted_student
    end
  end


  def confirmed;  verified;  end
  def confirmed?; verified?; end

  protected

  def prepare
    self.contact_info_value = self.contact_info_value.try(:strip)
  end

  def initialize_tokens
    self.confirmation_pin = TokenMaker.contact_info_confirmation_pin
    self.confirmation_code = TokenMaker.contact_info_confirmation_code
  end
end
