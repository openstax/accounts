class AddIndexToContactInfoValue < ActiveRecord::Migration[5.2]
  def change
    add_index :contact_infos, [:value, :type], unique: true
  end
end
