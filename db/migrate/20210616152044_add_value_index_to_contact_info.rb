class AddValueIndexToContactInfo < ActiveRecord::Migration[5.2]
  def change
    add_index :contact_infos, :value, unique: true
  end
end
