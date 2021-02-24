class PreAuthState < ApplicationRecord
  belongs_to :user

  enum contact_info_kind: [:email_address]

  before_validation :prepare
  before_create :initialize_tokens

  include EmailAddressValidations

  email_validation_formats.each do |format|
    validates :contact_info_value, format: format,
                                   if: -> { !is_partial_info_allowed && email_address? }
  end

  validates :contact_info_kind, presence: true, unless: -> { is_partial_info_allowed }
  validates :contact_info_value, presence: true, unless: -> { is_partial_info_allowed }

  scope :contact_info_verified, -> { where(is_contact_info_verified: true) }

  def self.create_from_signed_data(data)
    role = User.roles[data[:role]] ? data['role'] : nil
    data['external_user_uuid'] = data.delete('uuid')
    PreAuthState.create!(
      is_partial_info_allowed: true,
      role: role,
      is_contact_info_verified: false,
      contact_info_value: data['email'],
      signed_data: data.merge(role: role)
    )
  end

  def signed?
    signed_data.present?
  end

  def signed_role?
    signed? && role == signed_data['role']
  end

  def signed_student?
    signed_role? && role == 'student'
  end

  def signed_instructor?
    signed_role? && role == 'instructor'
  end

  def signed_external_uuid
    signed? ? signed_data['external_user_uuid'] : nil
  end

  def confirmed
    is_contact_info_verified
  end

  def confirmed?
    is_contact_info_verified?
  end

  def linked_external_uuid
    UserExternalUuid.find_by_uuid(signed_external_uuid)
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
