class Group < ActiveRecord::Base

  serialize :cached_container_group_ids
  serialize :cached_member_group_ids

  has_many :group_members, dependent: :destroy, inverse_of: :group
  has_many :members, through: :group_members, source: :users

  has_many :container_group_nestings, dependent: :destroy, class_name: 'GroupNesting',
           foreign_key: :member_group_id, inverse_of: :member_group
  has_many :container_groups, through: :container_group_nestings

  has_many :member_group_nestings, dependent: :destroy, class_name: 'GroupNesting',
           foreign_key: :container_group_id, inverse_of: :container_group
  has_many :member_groups, through: :member_group_nestings

  has_many :oauth_applications, as: :owner, class_name: 'Doorkeeper::Application'

  validates_uniqueness_of :name, allow_nil: true

  scope :visible_for, lambda { |user|
    return where(is_public: true) unless user.is_a? User

    m_gids = user.member_groups.collect{ |g| g.parent_group_ids }.flatten
    s_gids = user.group_staffs.collect{ |gs| gs.group_id }
    gids = (m_gids + s_gids).uniq

    gt = Group.arel_table
    gt[:is_public].eq(true).or(
    gt[:id].in(gids))
  }

  def container_group_ids
    return cached_container_group_ids if cached_container_group_ids.is_a? Array
    gids_array = [id]
    gids_set = Set.new gids_array
    loop do
      gids_array = gids_set.to_a
      new_gids = GroupNesting.where{container_group_id.not_in gids_array}
                             .where(member_group_id: gids_array)
                             .pluck(:container_group_id)
      break if new_gids.empty?
      cached_gids = Group.where(id: new_gids).pluck(:cached_container_group_ids)
                         .flatten.compact
      gids_set.merge new_gids + cached_gids
    end
    update_attribute(:cached_container_group_ids, gids_array)
    gids_array
  end

  def member_group_ids
    return cached_member_group_ids if cached_member_group_ids.is_a? Array
    gids_array = [id]
    gids_set = Set.new gids_array
    loop do
      gids_array = gids_set.to_a
      new_gids = GroupNesting.where{member_group_id.not_in gids_array}
                             .where(container_group_id: gids_array)
                             .pluck(:member_group_id)
      break if new_gids.empty?
      cached_gids = Group.where(id: new_gids).pluck(:cached_member_group_ids)
                         .flatten.compact
      gids_set.merge new_gids + cached_gids
    end
    update_attribute(:cached_member_group_ids, gids_array)
    gids_array
  end

  def member_user_ids
    GroupMember.where(group_id: member_group_ids).pluck(:user_id)
  end

  def has_member?(obj)
    case obj
    when User
      member_user_ids.include?(obj.id)
    when Group
      member_group_ids.include?(obj.id)
    else
      false
    end
  end

  def has_staff?(user, role = nil)
    return false unless user.is_a? User
    role_options = (role ? {role: role.to_s} : {})
    !group_staffs.where(role_options.merge({user_id: user.id})).first.nil?
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
      gn = GroupNesting.new
      gn.container_group = self
      gn.member_group = obj
      return false unless gn.valid?
      gn.save if persisted?
      member_group_nestings << gn
      obj.container_group_nestings << gn
    else
      return false
    end
  end

  def add_staff(user, role = :viewer)
    return false unless user.is_a? User
    gs = GroupStaff.new
    gs.group = self
    gs.user = user
    gs.role = role
    gs.save if persisted?
    group_staffs << gs if gs.valid?
  end

end
