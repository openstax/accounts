class CreateGroupSharings < ActiveRecord::Migration
  def change
    create_table :group_sharings do |t|
      t.references :group, null: false
      t.references :shared_with, polymorphic: true, null: false
      t.boolean :can_edit, null: false, default: false

      t.timestamps
    end

    add_index :group_sharings, [:shared_with_id, :shared_with_type, :group_id],
                               name: 'index_group_sharings_on_sw_id_and_sw_type_and_g_id',
                               unique: true
  end
end
