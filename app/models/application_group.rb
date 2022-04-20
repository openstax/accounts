class ApplicationGroup < ApplicationRecord
  belongs_to :application, class_name: 'Doorkeeper::Application',
                           inverse_of: :application_groups
  belongs_to :group, inverse_of: :application_groups

  validates :group, :application, presence: true
  validates :group_id, uniqueness: { scope: :application_id }
end
