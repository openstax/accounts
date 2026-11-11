class AddSalesforcePushFieldsToAdoptionReports < ActiveRecord::Migration[6.1]
  def change
    add_column :adoption_reports, :how_using, :string, if_not_exists: true
    add_column :adoption_reports, :salesforce_book_name, :string, if_not_exists: true
    add_column :adoption_reports, :surface, :string, if_not_exists: true

    # Rows saved before salesforce_book_name existed stay unique by title; new rows are unique by abbreviation.
    remove_index :adoption_reports, column: [:user_id, :book_title, :school_year],
                                    unique: true, name: 'index_adoption_reports_on_user_book_year', if_exists: true
    add_index :adoption_reports, [:user_id, :book_title, :school_year],
              unique: true, where: 'salesforce_book_name IS NULL',
              name: 'index_adoption_reports_on_user_title_year_legacy', if_not_exists: true
    add_index :adoption_reports, [:user_id, :salesforce_book_name, :school_year],
              unique: true, where: 'salesforce_book_name IS NOT NULL',
              name: 'index_adoption_reports_on_user_sf_book_year', if_not_exists: true
  end
end
