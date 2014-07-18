class Group < ActiveRecord::Base

  has_many :group_users, dependent: :destroy, inverse_of: :group
  has_many :users, through: :group_users

  has_many :group_members, class_name: 'GroupUser', conditions: { role: 'member' }
  has_many :members, through: :group_members, source: :user

  has_many :permitter_group_groups, dependent: :destroy, class_name: 'GroupGroup',
           foreign_key: :permitted_group_id, inverse_of: :permitted_group
  has_many :permitter_groups, through: :permitter_group_groups

  has_many :permitted_group_groups, dependent: :destroy, class_name: 'GroupGroup',
           foreign_key: :permitter_group_id, inverse_of: :permitter_group
  has_many :permitted_groups, through: :permitted_group_groups

  has_many :oauth_applications, as: :owner, inverse_of: :owner,
           class_name: 'Doorkeeper::Application'

  validates_uniqueness_of :name, allow_nil: true

  scope :visible_for, lambda { |user|
    return where(is_public: true) unless user.is_a? User
    
    uid = user.id
    gids = user.group_users.pluck(:group_id)
    gt = Group.arel_table
    gut = GroupUser.arel_table
    ggt = GroupGroup.arel_table
    includes(:group_users).includes(:permitted_group_groups).where(
      gt[:is_public].eq(true).or(
      gut[:user_id].eq(uid)).or(
      ggt[:permitted_group_id].in(gids))
    )
  }

  def add_user(user, role = :member)
    users = user.is_a?(Array) ? user : [user]
    users.each do |user|
      gu = GroupUser.new
      gu.group = self
      gu.user = user
      gu.role = role
      gu.save if persisted?
      group_users << gu if gu.valid?
    end
  end

  def add_member(user)
    add_user(user, :member)
  end

  def add_permitted_group(group, role = :viewer)
    groups = group.is_a?(Array) ? group : [group]
    groups.each do |group|
      gg = GroupGroup.new
      gg.permitter_group = self
      gg.permitted_group = group
      gg.role = role
      return false unless gg.valid?
      gg.save if persisted?
      self.permitted_group_groups << gg
      group.permitter_group_groups << gg
    end
  end

  def has_role?(obj, role = nil)
    role_options = (role ? {role: role.to_s} : {})
    case obj
    when User
      return true if group_users.where(role_options.merge({user_id: obj.id})).first
      gids = obj.group_users.members.pluck(:group_id)
      return true if permitted_group_groups.where(
                       role_options.merge({permitted_group_id: gids})).first
      false
    when Group
      !!permitted_group_groups.where(role_options.merge({permitted_group_id: obj.id})).first
    else
      false
    end
  end

  def has_member?(obj)
    has_role?(obj, :member)
  end

end
