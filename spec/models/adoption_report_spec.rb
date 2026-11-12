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

    it 'only accepts the four Salesforce how_using values, or nil' do
      expect(build_report(how_using: nil)).to be_valid
      expect(build_report(how_using: AdoptionReport::HOW_USING_OPTIONS.last)).to be_valid
      expect(build_report(how_using: 'Sort of')).not_to be_valid
    end

    it 'only accepts known surfaces, or nil' do
      expect(build_report(surface: nil)).to be_valid
      expect(build_report(surface: 'impact')).to be_valid
      expect(build_report(surface: 'footer')).not_to be_valid
    end

    it 'is unique per user, Salesforce book name and school year' do
      build_report(salesforce_book_name: 'Biology', book_title: 'Biology 2e').save!
      dup = build_report(salesforce_book_name: 'Biology', book_title: 'Biology for AP')
      expect(dup).not_to be_valid
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

  describe '.pushable' do
    def create_report!(overrides = {})
      build_report({ salesforce_book_name: 'Bio', how_using: described_class::HOW_USING_OPTIONS.first }.merge(overrides)).tap(&:save!)
    end

    it 'includes complete modal and check-in rows' do
      modal = create_report!(book_title: 'A', salesforce_book_name: 'A')
      check_in = create_report!(book_title: 'B', salesforce_book_name: 'B', source: 'check_in')

      expect(described_class.pushable).to contain_exactly(modal, check_in)
    end

    it 'excludes check-in rows missing a book name or a use, not-using rows and pushed rows' do
      create_report!(book_title: 'A', salesforce_book_name: nil, source: 'check_in')
      create_report!(book_title: 'B', salesforce_book_name: 'B', source: 'check_in', how_using: nil)
      create_report!(book_title: 'C', salesforce_book_name: 'C', source: 'check_in', status: 'not_using')
      create_report!(book_title: 'D', salesforce_book_name: 'D', source: 'check_in', salesforce_pushed_at: Time.current)

      expect(described_class.pushable).to be_empty
    end

    it 'sends a considering book again once it becomes "using", even with nothing else changed' do
      report = build_report(status: 'considering', source: 'books_status', salesforce_book_name: 'Biology',
                            how_using: described_class::HOW_USING_OPTIONS.first, salesforce_pushed_at: 1.day.ago)
      report.save!

      report.update!(status: 'using', source: 'books_modal')

      expect(report.reload.salesforce_pushed_at).to be_nil
      expect(described_class.pushable).to include(report)
    end
  end

  describe 'local book-status answers' do
    it 'accepts considering and browsing from the Books tab' do
      %w[considering browsing].each_with_index do |status, index|
        report = build_report(status: status, source: 'books_status', book_title: "Book #{index}", salesforce_book_name: "B#{index}")
        expect(report).to be_valid
      end
    end

    it 'never makes them pushable, even with a book name and a use' do
      %w[considering browsing].each do |status|
        %w[books_status books_modal check_in].each do |source|
          build_report(status: status, source: source, book_title: "#{status}-#{source}", salesforce_book_name: "#{status}-#{source}",
                       how_using: described_class::HOW_USING_OPTIONS.first).save!
        end
      end

      expect(described_class.pushable).to be_empty
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

  describe 'review hold' do
    def saved_report(overrides = {})
      build_report({ salesforce_book_name: 'Bio', how_using: described_class::HOW_USING_OPTIONS.first }.merge(overrides)).tap(&:save!)
    end

    it 'defaults the threshold to 1000 students' do
      expect(Settings::Salesforce.adoption_review_student_threshold).to eq 1000
    end

    it 'holds a using report over the threshold' do
      expect(saved_report(students: 1001).review_status).to eq 'needs_review'
    end

    it 'does not hold a report at the threshold, over it for another status, or without a count' do
      expect(saved_report(students: 1000).review_status).to be_nil
      expect(saved_report(students: 5000, status: 'not_using', book_title: 'N', salesforce_book_name: 'N').review_status).to be_nil
      expect(saved_report(students: nil, book_title: 'Z', salesforce_book_name: 'Z').review_status).to be_nil
    end

    it 'follows a changed threshold setting' do
      allow(Settings::Salesforce).to receive(:adoption_review_student_threshold).and_return(100)
      expect(saved_report(students: 101).review_status).to eq 'needs_review'
    end

    it 'clears the flag when the count is edited back down to the threshold' do
      report = saved_report(students: 5000)
      report.update!(students: 1000)
      expect(report.review_status).to be_nil
    end

    it 'flags a report switched to using with a big count already saved' do
      report = saved_report(students: 5000, status: 'considering', source: 'books_status')
      expect(report.review_status).to be_nil
      report.update!(status: 'using', source: 'books_modal')
      expect(report.review_status).to eq 'needs_review'
    end

    it 'keeps an approval until the count changes' do
      report = saved_report(students: 5000)
      report.update!(review_status: 'approved', reviewed_at: Time.current, reviewed_by: user)

      report.update!(how_using: described_class::HOW_USING_OPTIONS.second)
      expect(report.review_status).to eq 'approved'
      expect(report.reviewed_at).to be_present

      report.update!(students: 6000)
      expect(report.review_status).to eq 'needs_review'
      expect(report.reviewed_at).to be_nil
      expect(report.reviewed_by).to be_nil
    end

    it 'keeps a rejection until the count changes' do
      report = saved_report(students: 5000)
      report.update!(review_status: 'rejected', reviewed_at: Time.current, reviewed_by: user)

      report.update!(school_year: '2026 - 27')
      expect(report.review_status).to eq 'rejected'

      report.update!(students: 400)
      expect(report.review_status).to be_nil
    end

    it 'honors a reviewer approving with a lower count in the same save' do
      report = saved_report(students: 5000)
      report.update!(students: 800, review_status: 'approved', reviewed_at: Time.current, reviewed_by: user)
      expect(report.review_status).to eq 'approved'
    end

    it 'leaves a report already pushed to Salesforce alone' do
      report = saved_report(students: 40, salesforce_pushed_at: 1.day.ago)
      report.update!(students: 9000)
      expect(report.review_status).to be_nil
    end

    it 'excludes held and rejected reports from pushable but includes approved ones' do
      held = saved_report(students: 5000, book_title: 'A', salesforce_book_name: 'A')
      rejected = saved_report(students: 5000, book_title: 'B', salesforce_book_name: 'B')
      rejected.update!(review_status: 'rejected')
      approved = saved_report(students: 5000, book_title: 'C', salesforce_book_name: 'C')
      approved.update!(review_status: 'approved')
      normal = saved_report(students: 40, book_title: 'D', salesforce_book_name: 'D')

      expect(held.review_status).to eq 'needs_review'
      expect(described_class.pushable).to contain_exactly(approved, normal)
    end

    it 'rejects an unknown review status' do
      expect(build_report(review_status: 'maybe')).not_to be_valid
    end
  end
end
