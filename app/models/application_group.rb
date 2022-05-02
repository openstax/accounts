class ApplicationGroup < ApplicationRecord
  belongs_to :application, class_name: 'Doorkeeper::Application',
                           inverse_of: :application_groups
  belongs_to :group, inverse_of: :application_groups

  validates_presence_of :group, :application
  validates_uniqueness_of :group_id, scope: :application_id
end
