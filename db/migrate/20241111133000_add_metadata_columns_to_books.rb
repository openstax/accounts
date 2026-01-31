class AddMetadataColumnsToBooks < ActiveRecord::Migration[6.1]
  def change
    add_column :books, :salesforce_name, :string unless column_exists?(:books, :salesforce_name)
    add_column :books, :webview_rex_link, :string unless column_exists?(:books, :webview_rex_link)
  end
end
