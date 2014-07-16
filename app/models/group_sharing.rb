class GroupSharing < ActiveRecord::Base
  belongs_to :group, inverse_of: :group_sharings
  belongs_to :shared_with, polymorphic: true

  validates_presence_of :group, :shared_with
  validates_uniqueness_of :group_id, scope: [:shared_with_id, :shared_with_type]
  validate :shared_with_user_or_group

  protected

  def shared_with_user_or_group
    return if shared_with.nil? || shared_with.is_a?(User) || shared_with.is_a?(Group)
    errors.add(:shared_with, 'must be either a User or a Group')
    false
  end
end
