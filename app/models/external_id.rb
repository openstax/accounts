class ExternalId < ApplicationRecord
  belongs_to :user, inverse_of: :external_ids

  enum(role: User::VALID_ROLES)

  validates :user, presence: true
  validates :external_id, presence: true, uniqueness: { scope: :role }
end
