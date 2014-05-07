class Group < ActiveRecord::Base
  has_many :group_users, :dependent => :destroy, :inverse_of => :group
  has_many :users, :through => :group_users

  has_many :oauth_applications, class_name: 'Doorkeeper::Application',
                                as: :owner,
                                dependent: :destroy

  accepts_nested_attributes_for :group_users, :allow_destroy => true

  attr_accessible :name, :group_users_attributes

  validates_presence_of :name

  scope :visible_for, lambda { |user|
    return none if user.nil?

    joins{users.deputies.outer}\
      .where{q = (users.id == user.id) |\
                 (users.deputies.id == user.id)
             q |= (container_id == nil) if user.is_admin?
             q}\
      .group(:id)
  }

  def group_user_for(user)
    group_users.where(:user_id => user.try(:id)).first
  end
  
  def add_user(user, options = {})
    gu = GroupUser.new(:is_manager => options[:manager],
                       :is_owner => options[:owner])
    gu.group = self
    gu.user = user
    group_users << gu
  end

  def has_user?(user)
    !group_user_for(user).nil?
  end

  def has_manager?(user)
    gu = group_user_for(user)
    !gu.nil? && gu.is_manager
  end

  def has_owner?(user)
    gu = group_user_for(user)
    !gu.nil? && gu.is_owner
  end

  def consistency_checks
    return destroy if group_users.empty?

    group_users.first.update_attribute(:is_owner, true) \
      if group_users.owners.first.nil?
  end
end
