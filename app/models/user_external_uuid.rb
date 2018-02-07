class UserExternalUuid < ActiveRecord::Base

  belongs_to :user, inverse_of: :external_uuids

  validates :user, presence: true
  validates :uuid, presence: true, uniqueness: true
end
