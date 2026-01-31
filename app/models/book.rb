class Book < ApplicationRecord
  has_many :user_books, dependent: :restrict_with_exception

  validates :book_uuid, presence: true, uniqueness: true
  validates :title, presence: true

  def self.find_or_create_from_catalog!(attributes)
    attrs = attributes.respond_to?(:to_h) ? attributes.to_h : {}
    attrs = attrs.deep_symbolize_keys

    uuid = attrs[:book_uuid].to_s.strip
    raise ArgumentError, 'book_uuid is required' if uuid.blank?

    book = find_or_initialize_by(book_uuid: uuid)

    book.title            = attrs[:title].presence || book.title || 'OpenStax Book'
    book.cover_url        = attrs[:cover_url].to_s if attrs[:cover_url].present?
    book.salesforce_name  = attrs[:salesforce_name].to_s if attrs[:salesforce_name].present?
    if attrs[:salesforce_book_id].present?
      book.salesforce_book_id = attrs[:salesforce_book_id].to_s
    end

    if attrs.key?(:assignable_book)
      book.assignable_book = ActiveModel::Type::Boolean.new.cast(attrs[:assignable_book])
    end

    book.webview_rex_link = attrs[:webview_rex_link].to_s if attrs[:webview_rex_link].present?
    book.html_url         = attrs[:html_url].to_s if attrs[:html_url].present?

    book.save! if book.new_record? || book.changed?
    book
  end
end
