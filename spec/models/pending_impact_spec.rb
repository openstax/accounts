require 'rails_helper'

RSpec.describe PendingImpact do
  let(:user) { FactoryBot.create(:user, role: User::INSTRUCTOR_ROLE) }
  let(:year) { SchoolYear.current }
  let!(:biology) { Book.create!(book_uuid: SecureRandom.uuid, title: 'Biology 2e', salesforce_name: 'Biology', salesforce_book_id: 'a0Z000000000001') }
  let!(:physics) { Book.create!(book_uuid: SecureRandom.uuid, title: 'College Physics 2e', salesforce_name: 'College Physics', salesforce_book_id: 'a0Z000000000002') }

  def report!(book, students:, status: 'using', school_year: year)
    AdoptionReport.create!(user: user, book: book, book_title: book.title, salesforce_book_name: book.salesforce_name,
                           school_year: school_year, source: 'books_modal', status: status, students: students)
  end

  def confirm!(book, school_year: year)
    Adoption.create!(salesforce_id: SecureRandom.hex(9), user: user, salesforce_book_id: book.salesforce_book_id,
                     school_year: school_year, base_year: school_year.to_i, students: 10,
                     confirmation_type: described_class::CONFIRMED_ADOPTION, rollover_status: false)
  end

  it 'counts this year\'s using reports that have no confirmed adoption yet' do
    report!(biology, students: 120)
    report!(physics, students: 45)
    report!(physics, students: 30, school_year: SchoolYear.label_for(SchoolYear.base_year_for(Time.zone.today) - 1))

    pending = described_class.new(user)

    expect(pending.books).to eq(2)
    expect(pending.students).to eq(165)
  end

  it 'drops a report once Salesforce confirms that book for the year' do
    report!(biology, students: 120)
    report!(physics, students: 45)
    confirm!(biology)

    expect(described_class.new(user).reports.map(&:book_title)).to eq(['College Physics 2e'])
  end

  it 'ignores not-using answers' do
    report!(biology, students: 120, status: 'not_using')

    expect(described_class.new(user)).not_to be_any
  end
end
