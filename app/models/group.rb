class Group < ActiveRecord::Base
  belongs_to :owner, polymorphic: true

  has_many :group_users, dependent: :destroy, inverse_of: :group
  has_many :users, through: :group_users

  has_many :oauth_applications, class_name: 'Doorkeeper::Application',
                                as: :owner,
                                dependent: :destroy

  validates_uniqueness_of :name, scope: [:owner_id, :owner_type]

  def group_user_for(user)
    group_users.where(:user_id => user.try(:id)).first
  end
  
  def add_user(user)
    gu = GroupUser.new
    gu.group = self
    gu.user = user
    gu.save if persisted?
    group_users << gu
  end

  def has_member?(user)
    !group_user_for(user).nil?
  end
  alias_method :has_user?, :has_member?

  def has_owner?(user)
    # TODO
  end
end
