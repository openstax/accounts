class CreateAuthentications < ActiveRecord::Migration[4.2]
  def change
    create_table :authentications do |t|
      t.integer :user_id
      t.string :provider
      t.string :uid

      t.timestamps null: false
    end

    add_index :authentications,
              [:user_id, :provider],
              name: 'index_authentications_on_user_id_scoped',
              unique: true
  end
end
