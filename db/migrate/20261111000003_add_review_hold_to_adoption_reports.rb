class AddReviewHoldToAdoptionReports < ActiveRecord::Migration[6.1]
  def change
    add_column :adoption_reports, :review_status, :string, if_not_exists: true
    add_column :adoption_reports, :reviewed_at, :datetime, if_not_exists: true
    add_reference :adoption_reports, :reviewed_by, foreign_key: { to_table: :users }, null: true, index: true, if_not_exists: true
    add_index :adoption_reports, :review_status, where: "review_status = 'needs_review'",
              name: 'index_adoption_reports_on_needs_review', if_not_exists: true
  end
end
