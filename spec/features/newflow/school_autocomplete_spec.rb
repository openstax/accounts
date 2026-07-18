require 'rails_helper'

module Newflow
  feature 'School name autocomplete', js: true do
    before do
      load 'db/seeds.rb'
      FactoryBot.create :school, name: 'Rice University', city: 'Houston', state: 'TX'
      FactoryBot.create :school, name: 'Rice County Community College', city: 'Lyons', state: 'KS'
    end

    scenario 'student picks a school from the suggestions' do
      visit newflow_signup_student_path

      fill_in 'signup[school]', with: 'Rice'

      expect(page).to have_css('.school-autocomplete-results li', text: 'Rice University')
      expect(page).to have_css('.school-autocomplete-results li', text: 'Houston, TX')

      find('.school-autocomplete-results li', text: 'Rice University', match: :first).click

      expect(find('[name="signup[school]"]').value).to eq 'Rice University'
      expect(find('[name="signup[school_id]"]', visible: :hidden).value).not_to be_empty
      expect(page).to have_no_css('.school-autocomplete-results li')
    end

    scenario 'student uses a school name not in the list' do
      visit newflow_signup_student_path

      fill_in 'signup[school]', with: 'Hogwarts Academy'

      expect(page).to have_css('.school-autocomplete-use-as-entered', text: 'Hogwarts Academy')

      find('.school-autocomplete-use-as-entered').click

      expect(find('[name="signup[school]"]').value).to eq 'Hogwarts Academy'
      expect(find('[name="signup[school_id]"]', visible: :hidden).value).to be_empty
    end

    scenario 'editing after picking clears the school link' do
      visit newflow_signup_student_path

      fill_in 'signup[school]', with: 'Rice'
      find('.school-autocomplete-results li', text: 'Rice University', match: :first).click
      expect(find('[name="signup[school_id]"]', visible: :hidden).value).not_to be_empty

      fill_in 'signup[school]', with: 'Rice University at'

      expect(find('[name="signup[school_id]"]', visible: :hidden).value).to be_empty
    end
  end
end
