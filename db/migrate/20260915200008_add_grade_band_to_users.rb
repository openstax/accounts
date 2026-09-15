class AddGradeBandToUsers < ActiveRecord::Migration[6.1]
  def change
    # Instructor-reported grade band, only asked/shown for K-12 educators on the
    # compressed instructor profile step (step 4). Nullable/free-form like
    # expected_start_semester -- valid values are enforced in the handler, not the DB.
    add_column :users, :grade_band, :string
  end
end
