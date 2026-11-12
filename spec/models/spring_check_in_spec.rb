require 'rails_helper'

# Spring window is January 2 to March 15 (AnnualCheckIn::SPRING_WINDOW); school year "2025 - 26"
# runs from 2025-08-01.
describe 'Spring check-in', type: :model do
  include ActiveSupport::Testing::TimeHelpers

  let(:today) { Time.zone.local(2026, 2, 10, 12) }

  around { |example| travel_to(today) { example.run } }

  def instructor(overrides = {})
    FactoryBot.create(:user, :terms_agreed, role: User::INSTRUCTOR_ROLE, created_at: 2.years.ago, **overrides)
  end

  def book(title)
    Book.create!(book_uuid: SecureRandom.uuid, title: title)
  end

  def save_book!(user, title)
    UserBook.create!(user: user, book: book(title))
  end

  def report!(user, title, year: '2025 - 26', status: 'using', **attrs)
    AdoptionReport.create!(user: user, book_title: title, school_year: year, status: status,
                           source: 'books_modal', **attrs)
  end

  before do
    allow_any_instance_of(FetchBookData).to receive(:books_by_subject).and_return([])
  end

  describe AnnualCheckIn do
    {
      [2025, 12, 31] => :fall,
      [2026, 1, 1] => :fall,
      [2026, 1, 2] => :spring,
      [2026, 3, 15] => :spring,
      [2026, 3, 16] => :fall
    }.each do |(year, month, day), term|
      it "is #{term} on #{year}-#{month}-#{day}" do
        date = Date.new(year, month, day)

        expect(described_class.term_on(date)).to eq term
        expect(described_class.spring?(date)).to eq(term == :spring)
      end
    end

    it 'reads the current day through Time.zone' do
      travel_to Time.zone.local(2026, 1, 1, 23, 59)
      expect(described_class.spring?).to be false

      travel_to Time.zone.local(2026, 1, 2, 0, 1)
      expect(described_class.spring?).to be true
    end

    it 'opens the window on January 2 of the current year' do
      expect(described_class.spring_window_start).to eq Time.zone.local(2026, 1, 2)
    end
  end

  describe User, '#check_in_term / #annual_check_in_due?' do
    it 'is spring for someone with no report this year, with the same card the fall asks' do
      user = instructor
      save_book!(user, 'Biology 2e')

      expect(user.check_in_term).to eq :spring
      expect(user.annual_check_in_due?).to be true
    end

    it 'is spring for someone who reported in the fall' do
      user = instructor
      save_book!(user, 'Biology 2e')
      report!(user, 'Biology 2e', students: 40)
      user.update!(check_in_completed_at: Time.zone.local(2025, 10, 1))

      expect(user.check_in_term).to eq :spring
      expect(user.annual_check_in_due?).to be true
    end

    it 'is not due once a check-in was confirmed since the window opened' do
      user = instructor
      save_book!(user, 'Biology 2e')
      report!(user, 'Biology 2e', students: 40)

      user.update!(check_in_completed_at: Time.zone.local(2026, 1, 2, 0, 0))
      expect(user.annual_check_in_due?).to be false

      user.update!(check_in_completed_at: Time.zone.local(2026, 1, 1, 23, 59))
      expect(user.annual_check_in_due?).to be true
    end

    it 'is not due while snoozed' do
      user = instructor(check_in_dismissed_at: 3.days.ago)
      save_book!(user, 'Biology 2e')

      expect(user.annual_check_in_due?).to be false
    end

    it 'is not due with nothing to ask about' do
      user = instructor
      save_book!(user, 'Biology 2e')
      report!(user, 'Biology 2e', status: 'considering')

      expect(user.check_in_term).to eq :spring
      expect(user.annual_check_in_due?).to be false
    end

    it 'keeps the fall eligibility rules' do
      student = instructor(role: User::STUDENT_ROLE)
      save_book!(student, 'Biology 2e')
      new_account = instructor(created_at: 3.months.ago)
      save_book!(new_account, 'Biology 2e')

      expect(student.annual_check_in_due?).to be false
      expect(new_account.annual_check_in_due?).to be false
    end

    context 'outside the window' do
      let(:today) { Time.zone.local(2026, 3, 16, 12) }

      it 'does not ask someone who reported in the fall' do
        user = instructor
        save_book!(user, 'Biology 2e')
        report!(user, 'Biology 2e', students: 40)

        expect(user.check_in_term).to be_nil
        expect(user.annual_check_in_due?).to be false
      end

      it 'still asks someone with no report this year, in fall terms' do
        user = instructor
        save_book!(user, 'Biology 2e')

        expect(user.check_in_term).to eq :fall
      end
    end
  end

  describe AnnualCheckIn, '#rows' do
    let(:user) { instructor }
    let(:check_in) { AnnualCheckIn.new(user, term: :spring) }

    it 'lists books reported as in use this year, prefilled with their students and use' do
      save_book!(user, 'Biology 2e')
      report!(user, 'Biology 2e', students: 40, how_using: AdoptionReport::HOW_USING_OPTIONS.second,
                                  salesforce_book_name: 'Biology')

      expect(check_in.rows).to contain_exactly(
        have_attributes(title: 'Biology 2e', students: 40, abbreviation: 'Biology',
                        how_using: AdoptionReport::HOW_USING_OPTIONS.second)
      )
    end

    it 'includes a confirmed adoption for this year even when the book was never saved' do
      chemistry = Book.create!(book_uuid: SecureRandom.uuid, title: 'Chemistry 2e', salesforce_book_id: 'a0Chem')
      Adoption.create!(salesforce_id: 'SF1', user: user, school_year: '2025 - 26', students: 75,
                       salesforce_book_id: chemistry.salesforce_book_id, confirmation_type: 'OpenStax Confirmed Adoption',
                       rollover_status: false)

      expect(check_in.rows).to contain_exactly(have_attributes(title: 'Chemistry 2e', students: 75))
    end

    it 'adds saved books not yet answered this year' do
      save_book!(user, 'Biology 2e')
      save_book!(user, 'Chemistry 2e')
      report!(user, 'Biology 2e', students: 40)

      expect(check_in.rows.map(&:title)).to contain_exactly('Biology 2e', 'Chemistry 2e')
      expect(check_in.rows.find { |row| row.title == 'Chemistry 2e' }.students).to be_nil
    end

    it 'preselects "using" only for books already reported in use this year' do
      save_book!(user, 'Biology 2e')
      save_book!(user, 'Chemistry 2e')
      report!(user, 'Biology 2e', students: 40)
      report!(user, 'Old Book', year: '2024 - 25', students: 10)

      expect(check_in.rows.to_h { |row| [row.title, row.status] }).to eq('Biology 2e' => 'using', 'Chemistry 2e' => nil)
      expect(AnnualCheckIn.new(user, term: :fall).rows.map(&:status)).to all(be_nil)
    end

    it 'leaves out saved books answered considering, browsing or not using this year' do
      %w[considering browsing not_using].each_with_index do |status, index|
        title = "Book #{index}"
        save_book!(user, title)
        report!(user, title, status: status)
      end
      save_book!(user, 'Biology 2e')

      expect(check_in.rows.map(&:title)).to eq ['Biology 2e']
    end

    it "does not pull in last year's books once something was reported this year" do
      report!(user, 'Biology 2e', students: 40)
      report!(user, 'Old Book', year: '2024 - 25', students: 10)

      expect(check_in.rows.map(&:title)).to eq ['Biology 2e']
    end

    it 'prefills from last year when nothing was reported this year, like the fall card' do
      report!(user, 'Old Book', year: '2024 - 25', students: 10)

      expect(check_in.rows).to contain_exactly(have_attributes(title: 'Old Book', students: 10))
    end

    it 'shows the fall rows unchanged in fall' do
      report!(user, 'Old Book', year: '2024 - 25', students: 10)
      report!(user, 'Biology 2e', students: 40)

      expect(AnnualCheckIn.new(user, term: :fall).rows.map(&:title)).to eq ['Old Book']
    end
  end

  describe AnnualCheckIn, '#copy' do
    let(:user) { instructor }

    it 'uses the spring wording, with the fall wording as the fallback' do
      spring = AnnualCheckIn.new(user, term: :spring)
      fall = AnnualCheckIn.new(user, term: :fall)

      expect(spring.copy(:heading)).to eq 'New term. Still teaching with these books?'
      expect(spring.copy(:body)).to eq 'Spring classes count toward 2025 - 26. Update anything that changed; it takes about a minute.'
      expect(spring.copy(:students_label)).to eq 'Students this school year (fall and spring together)'
      expect(spring.copy(:dismiss_button)).to eq 'Remind me later'

      expect(fall.copy(:heading)).to eq 'Are you teaching with these books in 2025 - 26?'
      expect(fall.copy(:students_label)).to eq 'Students'
    end
  end
end
