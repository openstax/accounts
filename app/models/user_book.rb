class UserBook < ApplicationRecord
  belongs_to :user
  belongs_to :book

  validates :book_id, uniqueness: { scope: :user_id }

  delegate :book_uuid, :title, :cover_url, :salesforce_name, :assignable_book, :webview_rex_link, :html_url,
           to: :book, allow_nil: true
end
