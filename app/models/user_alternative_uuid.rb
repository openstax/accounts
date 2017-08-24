class UserAlternativeUuid < ActiveRecord::Base

  belongs_to :user, inverse_of: :alternative_uuids

  validates :uuid, :user, presence: true
end
