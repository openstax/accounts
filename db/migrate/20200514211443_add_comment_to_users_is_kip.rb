class AddCommentToUsersIsKip < ActiveRecord::Migration[5.2]
  # rubocop:disable Rails/ReversibleMigration
  def change
    # Add a comment to the `is_kip` column in the users table
    change_column :users, :is_kip, :boolean,
comment: "is the User-s school a Key Institutional Partner?"
  end
  # rubocop:enable Rails/ReversibleMigration
end
