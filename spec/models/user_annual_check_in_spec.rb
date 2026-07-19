require 'rails_helper'

describe User, '#annual_check_in_due? / #check_in_required?', type: :model do
  # Freeze inside a school year (school year "2025 - 26" starts 2025-08-01)
  # so date-math edge cases (school-year start, 1-year-old accounts, the
  # 7-day snooze) are deterministic regardless of when the suite runs.
  around do |example|
    Timecop.freeze(Time.zone.local(2026, 3, 1, 12, 0, 0)) { example.run }
  end

  let(:school_year_start) { Time.zone.local(2025, 8, 1) }
  let(:old_enough_at) { 2.years.ago }

  def instructor(overrides = {})
    FactoryBot.create(
      :user,
      :terms_agreed,
      role: User::INSTRUCTOR_ROLE,
      created_at: old_enough_at,
      **overrides
    )
  end

  def give_adoption_signal!(user)
    book = Book.create!(book_uuid: SecureRandom.uuid, title: 'Intro to Sociology')
    UserBook.create!(user: user, book: book)
  end

  describe '#check_in_eligible_role?' do
    it 'excludes students' do
      user = instructor(role: User::STUDENT_ROLE)
      expect(user.check_in_eligible_role?).to be false
    end

    it 'excludes unknown_role' do
      user = instructor(role: User::UNKNOWN_ROLE)
      expect(user.check_in_eligible_role?).to be false
    end

    it 'includes instructor-like roles' do
      user = instructor(role: User::INSTRUCTOR_ROLE)
      expect(user.check_in_eligible_role?).to be true
    end
  end

  describe '#annual_check_in_due?' do
    it 'is false for a student, even with an adoption signal and an old account' do
      user = instructor(role: User::STUDENT_ROLE)
      give_adoption_signal!(user)

      expect(user.annual_check_in_due?).to be false
    end

    it 'is false for an unknown-role user' do
      user = instructor(role: User::UNKNOWN_ROLE)
      give_adoption_signal!(user)

      expect(user.annual_check_in_due?).to be false
    end

    it 'is false for an account created less than a year ago' do
      user = instructor(created_at: 3.months.ago)
      give_adoption_signal!(user)

      expect(user.annual_check_in_due?).to be false
    end

    it 'is false with no adoption signal at all' do
      user = instructor

      expect(user.annual_check_in_due?).to be false
    end

    it 'is true for an eligible instructor with a saved book and no prior completion' do
      user = instructor
      give_adoption_signal!(user)

      expect(user.annual_check_in_due?).to be true
    end

    it 'is true when the signal comes from an Adoption instead of a UserBook' do
      user = instructor
      Adoption.create!(salesforce_id: 'SF1', user: user, confirmation_type: 'x', rollover_status: false)

      expect(user.annual_check_in_due?).to be true
    end

    it 'is true when the signal comes from an AdoptionReport instead of a UserBook' do
      user = instructor
      AdoptionReport.create!(user: user, book_title: 'Bio 101', school_year: '2024 - 25', source: 'books_modal')

      expect(user.annual_check_in_due?).to be true
    end

    it 'is false once completed this school year' do
      user = instructor(check_in_completed_at: school_year_start + 1.day)
      give_adoption_signal!(user)

      expect(user.annual_check_in_due?).to be false
    end

    it 'is true again once the completion is from a prior school year' do
      user = instructor(check_in_completed_at: school_year_start - 1.day)
      give_adoption_signal!(user)

      expect(user.annual_check_in_due?).to be true
    end

    it 'is false while snoozed (dismissed within the last 7 days)' do
      user = instructor(check_in_dismissed_at: 3.days.ago, check_in_dismissal_count: 1)
      give_adoption_signal!(user)

      expect(user.annual_check_in_due?).to be false
    end

    it 'is true again once the snooze window (7 days) has passed' do
      user = instructor(check_in_dismissed_at: 10.days.ago, check_in_dismissal_count: 1)
      give_adoption_signal!(user)

      expect(user.annual_check_in_due?).to be true
    end
  end

  describe '#effective_check_in_dismissal_count' do
    it 'is 0 when never dismissed' do
      user = instructor
      expect(user.effective_check_in_dismissal_count).to eq 0
    end

    it 'is the stored count when dismissed within the current school year' do
      user = instructor(check_in_dismissed_at: school_year_start + 1.day, check_in_dismissal_count: 2)
      expect(user.effective_check_in_dismissal_count).to eq 2
    end

    it 'resets to 0 when the last dismissal predates the current school year' do
      user = instructor(check_in_dismissed_at: school_year_start - 1.day, check_in_dismissal_count: 2)
      expect(user.effective_check_in_dismissal_count).to eq 0
    end
  end

  describe '#check_in_required?' do
    it 'is false below the dismissal limit' do
      user = instructor(check_in_dismissed_at: 10.days.ago, check_in_dismissal_count: 1)
      give_adoption_signal!(user)

      expect(user.check_in_required?).to be false
    end

    it 'is true at the dismissal limit, once the snooze window has passed' do
      user = instructor(check_in_dismissed_at: 10.days.ago, check_in_dismissal_count: 2)
      give_adoption_signal!(user)

      expect(user.check_in_required?).to be true
    end

    it 'is false at the dismissal limit while still within the snooze window' do
      user = instructor(check_in_dismissed_at: 3.days.ago, check_in_dismissal_count: 2)
      give_adoption_signal!(user)

      expect(user.check_in_required?).to be false
    end

    it 'is false when the dismissal count reset for a new school year' do
      user = instructor(check_in_dismissed_at: school_year_start - 1.day, check_in_dismissal_count: 2)
      give_adoption_signal!(user)

      expect(user.check_in_required?).to be false
    end
  end

  describe '#check_in_streak_years' do
    # Frozen "now" is 2026-03-01, inside school year "2025 - 26", so the
    # pending/current year is 2025 and the immediately-prior completed
    # year is 2024 - 25.
    def report_for!(user, school_year)
      AdoptionReport.create!(
        user: user, book_title: 'Intro to Sociology', school_year: school_year, source: 'books_modal'
      )
    end

    it 'is 0 with no reports at all' do
      user = instructor
      expect(user.check_in_streak_years).to eq 0
    end

    it 'is 0 when only the current/pending year has a report (no completed prior years)' do
      user = instructor
      report_for!(user, '2025 - 26')

      expect(user.check_in_streak_years).to eq 0
    end

    it 'is 1 with a single consecutive prior year reported' do
      user = instructor
      report_for!(user, '2024 - 25')

      expect(user.check_in_streak_years).to eq 1
    end

    it 'is 2 with two consecutive prior years reported' do
      user = instructor
      report_for!(user, '2024 - 25')
      report_for!(user, '2023 - 24')

      expect(user.check_in_streak_years).to eq 2
    end

    it 'stops counting at the first gap' do
      user = instructor
      report_for!(user, '2024 - 25')
      # gap at 2023 - 24
      report_for!(user, '2022 - 23')

      expect(user.check_in_streak_years).to eq 1
    end

    it 'ignores multiple reports (different books) within the same school year' do
      user = instructor
      report_for!(user, '2024 - 25')
      AdoptionReport.create!(
        user: user, book_title: 'Chemistry Basics', school_year: '2024 - 25', source: 'books_modal'
      )

      expect(user.check_in_streak_years).to eq 1
    end
  end
end
