class AddHtmlUrlToBooks < ActiveRecord::Migration[6.0]
  def change
    add_column :books, :html_url, :string unless column_exists?(:books, :html_url)
  end
end
