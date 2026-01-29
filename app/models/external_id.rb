class ExternalId < ApplicationRecord
  belongs_to :user, inverse_of: :external_ids

  enum(role: User::VALID_ROLES)

  validates :user, presence: true
  validates :external_id, presence: true, uniqueness: { scope: :role }

  # Find an ExternalId by external_id and role, with backwards compatibility
  # for unknown_role records when a specific role is provided
  def self.find_by_external_id_and_role(external_id, role = nil)
    query = { external_id: external_id }
    query[:role] = [role, 'unknown_role'] unless role.nil?

    external_ids = where(query).to_a

    if role.nil?
      external_ids.first
    else
      # First try to find ExternalId with matching role
      result = external_ids.find { |ext_id| ext_id.role == role.to_s }
      # If no result, try to find ExternalId with unknown_role for backwards compatibility
      result || external_ids.find(&:unknown_role?)
    end
  end
end
