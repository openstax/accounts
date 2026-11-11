require 'rails_helper'

RSpec.describe ImpactHelper, type: :helper do
  def prompt(overrides = {})
    helper.impact_next_prompt(
      **{ streak_years: 0, saved_total: 0, saved_answered: 0, current_year_reported: true }.merge(overrides)
    )
  end

  describe '#impact_next_prompt' do
    it 'compares answered and saved books, and points to the Books tab instead of the modal' do
      result = prompt(saved_total: 3, saved_answered: 2)

      expect(result[:heading]).to eq('You’ve told us about 2 of your 3 saved books this year')
      expect(result[:body]).to start_with('Tell us where you are with the others.')
      expect(result[:button]).to eq('Go to my books')
      expect(result[:path]).to eq(account_books_path)
    end

    it 'celebrates years with OpenStax when this year is covered' do
      expect(prompt(streak_years: 2, saved_total: 1, saved_answered: 1)[:heading])
        .to eq('Year 3 with OpenStax. Thank you for sticking with us.')
    end

    it 'asks to keep this term current when nothing is reported yet, thanking past years' do
      result = prompt(current_year_reported: false, streak_years: 2)

      expect(result[:heading]).to eq('Report this term’s classes to keep your impact current')
      expect(result[:body]).to include('Thank you for 2 years of reporting.')
    end

    it 'never offers a student-count target' do
      [prompt, prompt(current_year_reported: false), prompt(saved_total: 2)].each do |result|
        expect("#{result[:heading]} #{result[:body]}").not_to match(/milestone|students to|students from/i)
      end
    end
  end

  describe '#impact_pending_badge' do
    it 'shows a visible count and a screen reader sentence' do
      html = helper.impact_pending_badge(120, 'student')

      expect(html).to include('+120 pending')
      expect(html).to include('Plus 120 students pending confirmation, not yet in the total.')
      expect(html).to include('sr-only')
    end

    it 'uses the singular noun for one and renders nothing for zero' do
      expect(helper.impact_pending_badge(1, 'book')).to include('Plus 1 book pending')
      expect(helper.impact_pending_badge(0, 'book')).to be_nil
    end
  end
end
