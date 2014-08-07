class GroupOwner < ActiveRecord::Base
  #sortable :user_id

  belongs_to :group, inverse_of: :group_owners
  belongs_to :user, inverse_of: :group_owners

  validates_presence_of :group, :user
  validates_uniqueness_of :user_id, scope: :group_id
end
