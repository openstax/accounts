require 'securerandom'

class CreateBooksAndUpdateUserBooks < ActiveRecord::Migration[6.1]
  class MigrationBook < ApplicationRecord
    self.table_name = 'books'
  end

  class MigrationUserBook < ApplicationRecord
    self.table_name = 'user_books'
  end

  def up
    create_table :books do |t|
      t.string :book_uuid, null: false
      t.string :title, null: false
      t.string :cover_url
      t.string :salesforce_name
      t.boolean :assignable_book, null: false, default: false
      t.string :webview_rex_link
      t.timestamps
    end

    add_index :books, :book_uuid, unique: true

    add_reference :user_books, :book, foreign_key: true

    MigrationUserBook.reset_column_information
    MigrationBook.reset_column_information

    say_with_time 'Backfilling books and linking saved entries' do
      MigrationUserBook.find_each do |user_book|
        next if user_book.book_id.present?

        uuid = user_book.book_uuid.presence || SecureRandom.uuid
        book = MigrationBook.find_or_create_by!(book_uuid: uuid) do |b|
          b.title = user_book.title.presence || 'OpenStax Book'
          b.cover_url = user_book.cover_url
          b.salesforce_name = user_book.salesforce_name
          b.assignable_book = user_book.assignable_book
          b.webview_rex_link = user_book.webview_rex_link
        end

        user_book.update!(book_id: book.id)
      end
    end

    change_column_null :user_books, :book_id, false

    remove_index :user_books, [:user_id, :book_uuid]
    remove_columns :user_books, :book_uuid, :title, :cover_url, :salesforce_name, :assignable_book, :webview_rex_link

    add_index :user_books, [:user_id, :book_id], unique: true
  end

  def down
    add_column :user_books, :book_uuid, :string, null: false, default: ''
    add_column :user_books, :title, :string, null: false, default: ''
    add_column :user_books, :cover_url, :string
    add_column :user_books, :salesforce_name, :string
    add_column :user_books, :assignable_book, :boolean, default: false, null: false
    add_column :user_books, :webview_rex_link, :string

    add_index :user_books, [:user_id, :book_uuid], unique: true

    MigrationUserBook.reset_column_information
    MigrationBook.reset_column_information

    say_with_time 'Restoring inline book attributes' do
      MigrationUserBook.find_each do |user_book|
        next unless user_book.book_id

        book = MigrationBook.find_by(id: user_book.book_id)
        next unless book

        user_book.update_columns(
          book_uuid: book.book_uuid,
          title: book.title,
          cover_url: book.cover_url,
          salesforce_name: book.salesforce_name,
          assignable_book: book.assignable_book,
          webview_rex_link: book.webview_rex_link
        )
      end
    end

    remove_reference :user_books, :book, foreign_key: true
    drop_table :books
  end
end
