class CreateMessageContactInfos < ActiveRecord::Migration
  def change
    create_table :message_contact_infos do |t|
      t.integer :message_id, null: false
      t.integer :contact_info_id, null: false
      t.string :type, null: false
      t.boolean :read, null: false, default: false

      t.timestamps
    end

    add_index :message_contact_infos, [:contact_info_id, :read]
    add_index :message_contact_infos, [:message_id, :contact_info_id],
                                      unique: true
  end
end
