class Group < ActiveRecord::Base

  serialize :cached_container_group_ids
  serialize :cached_member_group_ids

  has_many :group_owners, dependent: :destroy, inverse_of: :group
  has_many :owners, through: :group_owners, source: :user

  has_many :group_members, dependent: :destroy, inverse_of: :group
  has_many :members, through: :group_members, source: :user

  belongs_to :container_group, class_name: 'Group', inverse_of: :member_groups
  has_many :member_groups, class_name: 'Group',
           foreign_key: 'container_group_id', inverse_of: :container_group

  has_many :oauth_applications, as: :owner, class_name: 'Doorkeeper::Application'

  validate :no_loops
  validates_uniqueness_of :name, allow_nil: true

  before_save :invalidate_cached_group_ids, if: :container_group_id_changed?

  scope :visible_for, lambda { |user|
    next where(is_public: true) unless user.is_a? User

    includes(:group_members).includes(:group_owners)
    .where{((is_public.eq true) |\
             (group_members.user_id.eq my{user.id}) |\
             (group_owners.user_id.eq my{user.id}))}
  }

  def self.visible_trees_for(user)
    visible_groups = visible_for(user).to_a
    tree_ids = visible_groups.collect{|g| g.member_group_ids - [g.id]}.flatten
    visible_groups.select{|g| !tree_ids.include?(g.id)}
  end

  def container_group_ids
    return [] unless persisted?
    return cached_container_group_ids if cached_container_group_ids.is_a? Array
    gids = [id] + (container_group.try(:container_group_ids) || [])
    update_attribute(:cached_container_group_ids, gids)
    gids
  end

  def member_group_ids
    return [] unless persisted?
    return cached_member_group_ids if cached_member_group_ids.is_a? Array
    gids = [id] + member_groups.collect{|g| g.member_group_ids}.flatten
    update_attribute(:cached_member_group_ids, gids)
    gids
  end

  def has_member?(obj)
    case obj
    when User
      !GroupMember.where(group_id: member_group_ids, user_id: obj.id).first.nil?
    when Group
      member_group_ids.include?(obj.id)
    else
      false
    end
  end

  def has_owner?(user)
    return false unless user.is_a? User
    !group_owners.where(user_id: user.id).first.nil?
  end

  def add_member(obj)
    case obj
    when User
      gm = GroupMember.new
      gm.group = self
      gm.user = obj
      return false unless gm.valid?
      gm.save if persisted?
      group_members << gm
      obj.group_members << gm
    when Group
      obj.container_group = self
      return false unless obj.valid?
      obj.save if persisted?
      member_groups << obj
    else
      return false
    end
  end

  def add_owner(user)
    return false unless user.is_a? User
    go = GroupOwner.new
    go.group = self
    go.user = user
    go.save if persisted?
    group_owners << go if go.valid?
  end

  protected

  def no_loops
    return if container_group != self && !member_group_ids.include?(container_group_id)
    errors.add(:container_group, 'would create a loop')
    false
  end

  def invalidate_cached_group_ids
    old_group = Group.where(id: container_group_id_was).first
    new_group = container_group
    Group.where(id: (old_group.try(:container_group_ids) || []) +\
                    (new_group.try(:container_group_ids) || []))
         .update_all(cached_member_group_ids: nil)
    Group.where(id: member_group_ids).update_all(cached_container_group_ids: nil)
  end

end
