class AddCodeIndexToContactInfos < ActiveRecord::Migration[4.2]
  def change
    add_index :contact_infos, :confirmation_code, unique: true
  end
end
