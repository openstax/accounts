class GroupSupergroupPermission < ActiveRecord::Base
  belongs_to :group
  belongs_to :supergroup
  attr_accessible :permission
end
