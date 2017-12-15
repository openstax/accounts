class AddSupportIdentifierToUsers < ActiveRecord::Migration
  def change
    enable_extension :citext

    add_column :users, :support_identifier, :citext

    add_index :users, :support_identifier, unique: true

    User.find_each do |user|
      user.generate_support_identifier
      user.save!
    end

    change_column_null :users, :support_identifier, false
  end
end
