require 'rails_helper'

RSpec.describe Book, type: :model do
  subject(:book) { FactoryBot.create :book }

  it 'can create a book' do
    expect(book.salesforce_id).to start_with('a0Z')
    expect(book.salesforce_name).to_not be_nil
    expect(book.official_name).to_not be_nil
  end
end
