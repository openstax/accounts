require 'rails_helper'

RSpec.describe AccountCompletenessHelper, type: :helper do
  let(:user) { FactoryBot.create(:user, school: nil, self_reported_school: nil) }

  describe '#account_completeness_summary' do
    it 'marks nothing done for a brand-new user' do
      summary = helper.account_completeness_summary(user)

      expect(summary[:done_count]).to eq(0)
      expect(summary[:percent]).to eq(0)
      expect(summary[:items].map { |item| item[:done] }).to all(be false)
    end

    it 'marks school done when the user has a school' do
      school = FactoryBot.create(:school)
      user.update!(school: school)

      summary = helper.account_completeness_summary(user)
      school_item = summary[:items].find { |item| item[:key] == :school }

      expect(school_item[:done]).to eq(true)
    end

    it 'marks school done from a self-reported school even without a School record' do
      user.update!(self_reported_school: 'Rice University')

      summary = helper.account_completeness_summary(user)
      school_item = summary[:items].find { |item| item[:key] == :school }

      expect(school_item[:done]).to eq(true)
    end

    it 'marks books done once the user has a saved book' do
      book = Book.create!(book_uuid: SecureRandom.uuid, title: 'Intro to Sociology')
      UserBook.create!(user: user, book: book)

      summary = helper.account_completeness_summary(user)
      books_item = summary[:items].find { |item| item[:key] == :books }

      expect(books_item[:done]).to eq(true)
    end

    it 'marks adoption done from either a confirmed Adoption or a self-reported AdoptionReport' do
      user.adoption_reports.create!(
        book_title: 'Intro to Sociology', school_year: SchoolYear.current, source: 'books_modal', status: 'using'
      )

      summary = helper.account_completeness_summary(user)
      adoption_item = summary[:items].find { |item| item[:key] == :adoption }

      expect(adoption_item[:done]).to eq(true)
    end

    it 'marks LMS done once the user has answered' do
      user.update!(lms_used: 'canvas')

      summary = helper.account_completeness_summary(user)
      lms_item = summary[:items].find { |item| item[:key] == :lms }

      expect(lms_item[:done]).to eq(true)
    end

    it 'computes percent complete across all items' do
      user.update!(lms_used: 'canvas', self_reported_school: 'Rice University')

      summary = helper.account_completeness_summary(user)

      expect(summary[:done_count]).to eq(2)
      expect(summary[:percent]).to eq(50)
    end
  end

  describe '#account_completeness_chip_href' do
    it 'points the lms chip back at the overview with the card forced open' do
      href = helper.account_completeness_chip_href(:lms)

      expect(href).to include('show_lms=true')
      expect(href).to include('lms-question-card')
    end

    it 'points the books chip at the books tab' do
      expect(helper.account_completeness_chip_href(:books)).to eq(account_books_path)
    end
  end
end
