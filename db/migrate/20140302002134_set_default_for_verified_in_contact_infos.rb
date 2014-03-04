class SetDefaultForVerifiedInContactInfos < ActiveRecord::Migration
  def up
    change_column :contact_infos, :verified, :boolean, default: false, allow_nil: false
  end

  def down
    change_column :contact_infos, :verified, :boolean
  end
end
