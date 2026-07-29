require 'rails_helper'

RSpec.describe AdoptionReport, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { FactoryBot.create(:user, :terms_agreed) }

  def build_report(overrides = {})
    described_class.new({
      user: user,
      book_title: 'Test Book',
      school_year: '2025 - 26',
      status: 'using',
      source: 'books_modal'
    }.merge(overrides))
  end

  describe 'validations' do
    it 'is valid with the required attributes' do
      expect(build_report).to be_valid
    end

    it 'requires book_title' do
      report = build_report(book_title: nil)
      expect(report).not_to be_valid
      expect(report.errors[:book_title]).to be_present
    end

    it 'requires school_year' do
      report = build_report(school_year: nil)
      expect(report).not_to be_valid
      expect(report.errors[:school_year]).to be_present
    end

    it 'only accepts known statuses' do
      report = build_report(status: 'maybe')
      expect(report).not_to be_valid
      expect(report.errors[:status]).to be_present
    end

    it 'only accepts known sources' do
      report = build_report(source: 'carrier_pigeon')
      expect(report).not_to be_valid
      expect(report.errors[:source]).to be_present
    end

    it 'requires students to be a non-negative integer when present' do
      report = build_report(students: -1)
      expect(report).not_to be_valid
      expect(report.errors[:students]).to be_present
    end

    it 'allows students to be blank' do
      report = build_report(students: nil)
      expect(report).to be_valid
    end

    it 'enforces uniqueness of book_title scoped to user and school_year' do
      build_report.save!

      duplicate = build_report
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:book_title]).to be_present
    end

    it 'allows the same book_title for a different school year' do
      build_report.save!

      other_year = build_report(school_year: '2026 - 27')
      expect(other_year).to be_valid
    end

    it 'allows the same book_title for a different user' do
      build_report.save!

      other_user_report = build_report(user: FactoryBot.create(:user, :terms_agreed))
      expect(other_user_report).to be_valid
    end
  end

  describe 'scopes' do
    it 'unpushed returns only reports without a salesforce_pushed_at' do
      pushed = build_report(book_title: 'Pushed Book', salesforce_pushed_at: Time.zone.now)
      pushed.save!(validate: false)
      unpushed = build_report(book_title: 'Unpushed Book')
      unpushed.save!

      expect(described_class.unpushed).to include(unpushed)
      expect(described_class.unpushed).not_to include(pushed)
    end

    it 'using returns only reports with status using' do
      using = build_report(book_title: 'Using Book', status: 'using')
      using.save!
      not_using = build_report(book_title: 'Not Using Book', status: 'not_using')
      not_using.save!

      expect(described_class.using).to include(using)
      expect(described_class.using).not_to include(not_using)
    end
  end

  describe '.current_school_year_label' do
    it 'returns the year starting in August of the current calendar year when after July' do
      travel_to(Time.zone.local(2026, 9, 1)) do
        expect(described_class.current_school_year_label).to eq('2026 - 27')
      end
    end

    it 'returns the previous year start when before August' do
      travel_to(Time.zone.local(2026, 3, 1)) do
        expect(described_class.current_school_year_label).to eq('2025 - 26')
      end
    end
  end

  describe '#school_year_start' do
    it 'parses the leading 4-digit year out of a "YYYY - YY" label' do
      report = build_report(school_year: '2026 - 27')
      expect(report.school_year_start).to eq(2026)
    end

    it 'returns nil when the label has no leading year' do
      report = build_report(school_year: 'not a year')
      expect(report.school_year_start).to be_nil
    end
  end
end
