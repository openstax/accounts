class GroupSharing < ActiveRecord::Base
  belongs_to :group, inverse_of: :group_sharings
  belongs_to :shared_with, polymorphic: true

  validates_presence_of :group, :shared_with
  validates_uniqueness_of :group_id, scope: [:shared_with_id, :shared_with_type]
end
