class GroupMember < ApplicationRecord
  #sortable :user_id

  belongs_to :group, inverse_of: :group_members
  belongs_to :user, inverse_of: :group_members

  validates :group, :user, presence: true
  validates :user_id, uniqueness: { scope: :group_id }

  before_create :add_unread_update
  before_destroy :add_unread_update

  protected

  def add_unread_update
    group.add_unread_update
  end
end
