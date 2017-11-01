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
    role = User.roles[data[:role]] ? data['role'] : nil
    data['external_user_uuid'] = data.delete('uuid')
    SignupState.create!(
      role: role,
      verified: false,
      contact_info_value: data['email'],
      trusted_data: data.merge(role: role)
    )
  end

  def trusted?
    trusted_data.present?
  end

  def role_trusted?
    trusted? && role == trusted_data['role']
  end

  def trusted_student?
    role_trusted? && role == 'student'
  end

  def trusted_instructor?
    role_trusted? && role == 'instructor'
  end

  def trusted_external_uuid
    trusted? ? trusted_data['external_user_uuid'] : nil
  end

  def confirmed;  verified;  end
  def confirmed?; verified?; end

  def linked_external_uuid
    UserExternalUuid.find_by_uuid(trusted_external_uuid)
  end

  def on_user_authentication(user)
    if trusted_external_uuid
      existing_link = linked_external_uuid
      # Update uuid to point to new account if it's linked to a different one
      if existing_link
        if existing_link.user_id != user.id
          existing_link.update_attributes!(user: user)
        end
      else
        UserExternalUuid.create!(user: user, uuid: trusted_external_uuid)
      end
    end
  end

  protected

  def prepare
    self.contact_info_value = self.contact_info_value.try(:strip)
  end

  def initialize_tokens
    self.confirmation_pin = TokenMaker.contact_info_confirmation_pin
    self.confirmation_code = TokenMaker.contact_info_confirmation_code
  end
end
