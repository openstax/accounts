class AddFieldsToContactInfos < ActiveRecord::Migration
  def change
    add_column :contact_infos, :is_searchable, :boolean,
               :null => :false, :default => :false
    add_column :contact_infos, :public_value, :string
  end
end
