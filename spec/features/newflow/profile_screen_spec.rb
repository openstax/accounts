require 'rails_helper'

feature 'profile screen', js: true do
 describe 'resetting your password' do

 end

 describe 'adding a password (when you only have a social login ATM' do

 end

 describe 'adding an email address' do

 end


  describe 'adding a social login' do

  end

  describe 'deleting your password' do

  end

  describe 'editing your email' do

  end

  describe 'editing your name' do

  end

  describe 'log out' do

  end

  describe 'the cards under the profile' do
    let(:user) { create_user('profile_cards') }

    before do
      mock_current_user(user)
      visit '/i/profile'
    end

    context 'when the user is a student' do
      it 'leaves out the instructor-only adoption and newsletter cards' do
        expect(page).to have_css('.card h2', text: 'Find Your Book')
        expect(page).to have_css('.card h2', text: 'Get Help')
        expect(page).to have_no_css('.card h2', text: 'Using OpenStax?')
        expect(page).to have_no_css('.card h2', text: 'Keep in touch')
      end
    end

    context 'when the user is an instructor' do
      let(:user) do
        create_user('profile_cards').tap do |instructor|
          instructor.update!(role: User::INSTRUCTOR_ROLE, faculty_status: User::CONFIRMED_FACULTY)
        end
      end

      it 'shows the adoption and newsletter cards' do
        expect(page).to have_css('.card h2', text: 'Using OpenStax?')
        expect(page).to have_css('.card h2', text: 'Keep in touch')
      end
    end
  end

end
