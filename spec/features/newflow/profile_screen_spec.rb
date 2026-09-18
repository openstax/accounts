require 'rails_helper'

feature 'profile screen', js: true do
 let!(:user) { create_newflow_user('user@openstax.org', 'password', terms_agreed: true) }

 before do
   turn_on_student_feature_flag
 end

 describe 'resetting your password' do

 end

 describe 'adding a password (when you only have a social login ATM' do

 end

 describe 'adding an email address' do

 end

 describe 'adding a social login' do
   scenario 'clicking a provider from profile adds it through the POST request phase' do
     newflow_log_in_user('user@openstax.org', 'password')
     wait_for_successful_log_in
     visit profile_newflow_path
     expect(page).to have_current_path(profile_newflow_path)

     simulate_login_signup_with_social(email: 'user@openstax.org', uid: 'uid123') do
       find('.other-sign-in summary').click
       find('[data-provider=facebooknewflow] .add--newflow').click

       expect(page).to have_current_path(profile_newflow_path)
       expect(user.authentications.reload.pluck(:provider)).to include('facebooknewflow')
     end
   end

 end

  describe 'deleting your password' do

  end

  describe 'editing your email' do

  end

  describe 'editing your name' do

  end

  describe 'log out' do

  end

end
