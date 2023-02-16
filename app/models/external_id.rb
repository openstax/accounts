class ExternalId < ApplicationRecord
  belongs_to :user, inverse_of: :external_ids

  validates :user, presence: true
  validates :external_id, presence: true, uniqueness: true
end
