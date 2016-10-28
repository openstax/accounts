class AddIsSearchableToContactInfos < ActiveRecord::Migration
  def change
    add_column :contact_infos, :is_searchable, :boolean, null: :false, default: :false
  end
end
