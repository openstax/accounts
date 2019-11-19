class AddIndexToContactInfos < ActiveRecord::Migration[5.2]
  def change
    add_index :contact_infos, :verified
  end
end
