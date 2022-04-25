class ChangeUserDefaults < ActiveRecord::Migration[4.2]
  # rubocop:disable Rails/ReversibleMigration
  def change
    change_column_default :users, :username, nil
    change_column_default :users, :state, "needs_profile"
  end
  # rubocop:enable Rails/ReversibleMigration
end
