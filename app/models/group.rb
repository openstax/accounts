class Group < ApplicationRecord

  has_many :group_owners, dependent: :destroy, inverse_of: :group
  has_many :owners, through: :group_owners, source: :user

  has_many :group_members, dependent: :destroy, inverse_of: :group
  has_many :members, through: :group_members, source: :user

  has_many :oauth_applications, as: :owner, class_name: 'Doorkeeper::Application'

  validates_uniqueness_of :name, allow_nil: true

  def has_owner?(user)
    return false unless user.is_a? User
    !group_owners.where(user_id: user.id).first.nil?
  end

  def has_member?(user)
    return false unless user.is_a? User
    !group_members.where(user_id: user.id).first.nil?
  end

  def add_owner(user)
    return false unless user.is_a? User
    go = GroupOwner.new
    go.group = self
    go.user = user
    return false unless go.valid?
    go.save if persisted?
    group_owners << go
  end

  def add_member(user)
    return false unless user.is_a? User
    gm = GroupMember.new
    gm.group = self
    gm.user = user
    return false unless gm.valid?
    gm.save if persisted?
    group_members << gm
  end

end
