class UserExternalUuid < ActiveRecord::Base

  belongs_to :user, inverse_of: :external_uuids

  validates :uuid, :user, presence: true, uniqueness: true
end
