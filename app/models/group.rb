class Group < ActiveRecord::Base
  belongs_to :owner, class_name: 'User', inverse_of: :owned_groups

  has_many :group_sharings, inverse_of: :group
  has_many :shared_with_users, through: :group_sharings,
           source: :shared_with, source_type: 'User'
  has_many :shared_with_groups, through: :group_sharings,
           source: :shared_with, source_type: 'Group'

  has_many :group_users, dependent: :destroy, inverse_of: :group
  has_many :users, through: :group_users

  has_many :oauth_applications, as: :owner, class_name: 'Doorkeeper::Application'

  validates_uniqueness_of :name, allow_nil: true

  scope :visible_for, lambda { |user|
    uid = user.id
    gids = user.group_users.pluck(:group_id)
    gt = Group.arel_table
    gut = GroupUser.arel_table
    gst = GroupSharing.arel_table
    includes(:group_users).includes(:group_sharings).where(
      gt[:visibility].eq('public').or(
      gt[:owner_id].eq(uid)).or(
      gut[:user_id].eq(uid)).or(
      gst[:shared_with_id].eq(uid).and(gst[:shared_with_type].eq('User'))).or(
      gst[:shared_with_id].in(gids).and(gst[:shared_with_type].eq('Group')))
    )
  }

  def add_user(user)
    # TODO: make routine?
    users = user.is_a?(Array) ? user : [user]
    users.each do |user|
      gu = GroupUser.new
      gu.group = self
      gu.user = user
      gu.save if persisted?
      group_users << gu if gu.valid?
    end
  end
  alias_method :add_users, :add_user

  def group_user_for(user)
    return unless user.is_a? User
    group_users.where(:user_id => user.id).first
  end

  def has_member?(user)
    !group_user_for(user).nil?
  end

  def share_with(obj, can_edit = false)
    # TODO: make routine?
    gs = GroupSharing.new
    gs.group = self
    gs.shared_with = obj
    gs.can_edit = can_edit
    gs.save!
  end

  def group_sharing_for(obj)
    group_sharings.where(:shared_with_id => obj.id,
                         :shared_with_type => obj.class.name).first
  end
end
