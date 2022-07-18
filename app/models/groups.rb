class Group < ApplicationRecord
  serialize :cached_supertree_group_ids
  serialize :cached_subtree_group_ids
  has_many :group_members, dependent: :destroy, inverse_of: :group
  has_many :members, through: :group_members, source: :user
  has_many :oauth_applications, as: :owner, class_name: 'Doorkeeper::Application'
  has_many :application_groups, dependent: :destroy, inverse_of: :group
  validates_uniqueness_of :name, allow_nil: true
  before_save :add_unread_update
  scope :visible_for, lambda { |user|
    next where(is_public: true) unless user.is_a? User
    group = left_joins(:group_members, :group_owners)
    group.where(is_public: true)
         .or(group.where(group_members: { user_id: user.id }))
         .or(group.where(group_owners: { user_id: user.id }))
  }
end
