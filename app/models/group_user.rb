class GroupUser < ActiveRecord::Base
  #sortable :user_id

  belongs_to :group, inverse_of: :group_users
  belongs_to :user, inverse_of: :group_users

  validates_presence_of :user, :group
  validates_uniqueness_of :user_id, scope: :group_id
end
