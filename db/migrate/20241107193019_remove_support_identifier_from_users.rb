class RemoveSupportIdentifierFromUsers < ActiveRecord::Migration[6.1]
  def up
    remove_column :users, :support_identifier
  end

  def down
    add_column :users, :support_identifier, :citext

    add_index :users, :support_identifier, unique: true

    User.find_each do |user|
      User.where(id: user.id).update_all(support_identifier: user.generate_support_identifier)
    end

    change_column_null :users, :support_identifier, false
  end
end
