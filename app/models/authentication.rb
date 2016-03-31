class Authentication < ActiveRecord::Base
  attr_accessible :provider, :uid, :user_id

  belongs_to :user, inverse_of: :authentications

  validates :provider, presence: true
  validates :uid, presence: true, uniqueness: { scope: :provider }

  before_destroy :check_not_last

  protected

  def check_not_last
    errors.add(:base, "Cannot delete an activated user's last authentication") \
      if user.authentications.size == 1 && user.is_activated?
    errors.none?
  end
end
