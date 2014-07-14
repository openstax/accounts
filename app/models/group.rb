class Group < ActiveRecord::Base
  belongs_to :supergroup, inverse_of: :groups

  has_many :group_users, dependent: :destroy, inverse_of: :group
  has_many :users, through: :group_users

  has_many :oauth_applications, class_name: 'Doorkeeper::Application',
                                as: :owner,
                                dependent: :destroy

  attr_accessible :name

  validates :name, uniqueness: true, allow_nil: true
  validates :group_users, presence: true

  after_create :maintenance

  def group_user_for(user)
    group_users.where(:user_id => user.try(:id)).first
  end
  
  def add_user(user, access_level = GroupUser::MEMBER)
    gu = GroupUser.new(access_level: access_level)
    gu.group = self
    gu.user = user
    gu.save if persisted?
    group_users << gu
  end

  def has_member?(user)
    !group_user_for(user).nil?
  end
  alias_method :has_user?, :has_member?

  def has_manager?(user)
    gu = group_user_for(user)
    !gu.nil? && gu.is_manager?
  end

  def has_owner?(user)
    gu = group_user_for(user)
    !gu.nil? && gu.is_owner?
  end

  def maintenance
    remaining_users = group_users(true)

    # Destroy group if everyone left
    return destroy if remaining_users.empty?

    remaining_managers = remaining_users.select{|gu| gu.access_level >= GroupUser::MANAGER}
    remaining_owners = remaining_users.select{|gu| gu.access_level >= GroupUser::OWNER}

    # Promote some user to owner if all owners left
    if remaining_managers.empty?
      remaining_users.first.update_attribute(:access_level, GroupUser::OWNER)
    elsif remaining_owners.empty?
      remaining_managers.first.update_attribute(:access_level, GroupUser::OWNER)
    end
  end
end
