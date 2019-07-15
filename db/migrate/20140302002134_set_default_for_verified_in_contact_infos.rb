class SetDefaultForVerifiedInContactInfos < ActiveRecord::Migration[4.2]
  def up
    change_column :contact_infos, :verified, :boolean, default: false, allow_nil: false
  end

  def down
    change_column :contact_infos, :verified, :boolean
  end
end
