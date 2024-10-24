class ApplicationUser < ApplicationRecord
  belongs_to :application, class_name: 'Doorkeeper::Application',
                           inverse_of: :application_users
  belongs_to :user, inverse_of: :application_users

  belongs_to :default_contact_info, class_name: 'ContactInfo'

  validates_presence_of :user, :application
  validates_uniqueness_of :user_id, scope: :application_id
  validate :contact_info_belongs_to_user

  def contact_info_belongs_to_user
    return if default_contact_info.nil? || default_contact_info.user == user
    errors.add(:default_contact_info, 'must belong to the given user.')
    false
  end
end
