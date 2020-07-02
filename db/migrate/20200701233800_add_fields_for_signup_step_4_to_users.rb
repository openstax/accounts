class AddFieldsForSignupStep4ToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :other_role_name, :string
    add_column :users, :how_many_students, :string
    add_column :users, :which_books, :string
    add_column :users, :who_chooses_books, :string
    add_column :users, :using_openstax_how, :integer
  end
end
