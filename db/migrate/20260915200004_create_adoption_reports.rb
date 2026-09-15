class CreateAdoptionReports < ActiveRecord::Migration[6.1]
  def change
    create_table :adoption_reports do |t|
      t.references :user, null: false, foreign_key: true
      t.references :book, foreign_key: true
      t.string :book_title, null: false
      t.string :school_year, null: false
      t.string :status, null: false, default: 'using'
      t.integer :students
      t.string :source, null: false, default: 'books_modal'
      t.datetime :salesforce_pushed_at
      t.string :salesforce_id
      t.timestamps
    end

    add_index :adoption_reports, [:user_id, :book_title, :school_year],
              unique: true, name: 'index_adoption_reports_on_user_book_year'
    add_index :adoption_reports, :salesforce_pushed_at
  end
end
