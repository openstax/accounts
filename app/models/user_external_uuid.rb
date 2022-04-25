class UserExternalUuid < ApplicationRecord

  belongs_to :user, inverse_of: :external_uuids

  validates :uuid, presence: true, uniqueness: true # rubocop:disable Rails/UniqueValidationWithoutIndex
end
