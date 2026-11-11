require 'rails_helper'

RSpec.describe User, '#titles_reported_for' do
  let(:user) { FactoryBot.create(:user, role: User::INSTRUCTOR_ROLE) }
  let(:year) { SchoolYear.current }
  let(:last_year) { SchoolYear.label_for(SchoolYear.base_year_for(Time.zone.today) - 1) }
  let!(:biology) { Book.create!(book_uuid: SecureRandom.uuid, title: 'Biology 2e', salesforce_book_id: 'a0Z000000000011') }
  let!(:physics) { Book.create!(book_uuid: SecureRandom.uuid, title: 'College Physics 2e', salesforce_book_id: 'a0Z000000000012') }

  def confirm!(book, school_year)
    Adoption.create!(salesforce_id: SecureRandom.hex(9), user: user, salesforce_book_id: book.salesforce_book_id,
                     school_year: school_year, students: 10, confirmation_type: 'OpenStax Confirmed Adoption',
                     rollover_status: false)
  end

  it 'counts both pending reports and confirmed adoptions for the year, once each' do
    AdoptionReport.create!(user: user, book: physics, book_title: physics.title, school_year: year,
                           source: 'books_modal', status: 'using')
    AdoptionReport.create!(user: user, book: biology, book_title: biology.title, school_year: year,
                           source: 'books_modal', status: 'using')
    confirm!(biology, year)
    confirm!(physics, last_year)

    expect(user.titles_reported_for(year)).to match_array(['Biology 2e', 'College Physics 2e'])
    expect(user.titles_reported_for(last_year)).to eq(['College Physics 2e'])
  end

  it 'ignores not-using answers' do
    AdoptionReport.create!(user: user, book: biology, book_title: biology.title, school_year: year,
                           source: 'check_in', status: 'not_using')

    expect(user.titles_reported_for(year)).to be_empty
  end
end

RSpec.describe User, '#titles_answered_for' do
  let(:user) { FactoryBot.create(:user, role: User::INSTRUCTOR_ROLE) }
  let(:year) { SchoolYear.current }
  let(:last_year) { SchoolYear.label_for(SchoolYear.base_year_for(Time.zone.today) - 1) }
  let!(:biology) { Book.create!(book_uuid: SecureRandom.uuid, title: 'Biology 2e', salesforce_book_id: 'a0Z000000000021') }

  def answer!(title, status, school_year = year)
    AdoptionReport.create!(user: user, book_title: title, school_year: school_year, source: 'books_status', status: status)
  end

  it 'counts every status for the year plus confirmed adoptions, once each' do
    %w[using not_using considering browsing].each { |status| answer!("Title #{status}", status) }
    answer!('Last year only', 'considering', last_year)
    Adoption.create!(salesforce_id: SecureRandom.hex(9), user: user, salesforce_book_id: biology.salesforce_book_id,
                     school_year: year, students: 10, confirmation_type: 'OpenStax Confirmed Adoption', rollover_status: false)
    answer!('Biology 2e', 'considering')

    expect(user.titles_answered_for(year)).to match_array(
      ['Title using', 'Title not_using', 'Title considering', 'Title browsing', 'Biology 2e']
    )
  end

  it 'leaves titles_reported_for counting only using and confirmed' do
    answer!('Mine', 'considering')

    expect(user.titles_reported_for(year)).to be_empty
  end
end
