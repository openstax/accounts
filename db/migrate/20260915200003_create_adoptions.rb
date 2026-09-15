class CreateAdoptions < ActiveRecord::Migration[6.1]
  def change
    create_table :adoptions do |t|
      t.string :salesforce_id, null: false
      t.string :adoption_number
      t.string :salesforce_name
      t.string :adoption_type
      t.string :school_year
      t.integer :base_year
      t.string :terms_used
      t.string :how_using
      t.text :languages, array: true, default: []
      t.integer :students
      t.date :class_start_date
      t.date :confirmation_date
      t.string :confirmation_type
      t.text :notes
      t.text :tracking_parameters
      t.string :assignable_adoption_status
      t.integer :assignable_assignments_created_count
      t.date :assignable_first_assignment_created_date
      t.date :assignable_most_recent_created_date
      t.string :salesforce_account_id
      t.string :salesforce_contact_id
      t.string :salesforce_opportunity_id
      t.boolean :rollover_status, default: false, null: false
      t.integer :likely_to_adopt_score
      t.references :user, foreign_key: true, null: true
      t.references :school, foreign_key: true, null: true
      t.string :salesforce_book_id
      t.decimal :savings, precision: 14, scale: 2

      t.timestamps
    end

    add_index :adoptions, :salesforce_id, unique: true
    add_index :adoptions, [:salesforce_contact_id, :school_year], name: 'index_adoptions_on_sf_contact_and_school_year'
    add_index :adoptions, [:salesforce_account_id, :school_year], name: 'index_adoptions_on_sf_account_and_school_year'
    add_index :adoptions, :salesforce_account_id
    add_index :adoptions, :salesforce_contact_id
    add_index :adoptions, :salesforce_opportunity_id
    add_index :adoptions, :salesforce_book_id
  end
end
