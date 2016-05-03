class AddConfirmationPinToContactInfos < ActiveRecord::Migration
  def change
    add_column :contact_infos, :confirmation_pin, :string
    add_index :contact_infos, :confirmation_pin
  end
end
