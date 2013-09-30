class AddCodeIndexToContactInfos < ActiveRecord::Migration
  def change
    add_index :contact_infos, :confirmation_code, unique: true
  end
end
