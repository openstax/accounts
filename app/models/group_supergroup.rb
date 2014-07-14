class GroupSupergroup < ActiveRecord::Base
  belongs_to :group
  belongs_to :supergroup
  # attr_accessible :title, :body
end
