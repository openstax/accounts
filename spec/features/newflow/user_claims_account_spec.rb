require 'rails_helper'

feature 'User claims an unclaimed account', js: true do
  before do
    turn_on_student_feature_flag
  end

  background { load 'db/seeds.rb' }
  let!(:app)   { create_default_application }
  let(:user_email) { 'unclaimeduser@example.com' }
  let(:user_options) {
    {
      email: user_email,
      application: app,
      username: 'therulerofallthings',
      first_name: Faker::Name.first_name,
      last_name: Faker::Name.last_name,
      already_verified: false
    }
  }

  def visit_invite_url
    perform_enqueued_jobs
    delivery = ActionMailer::Base.deliveries.last
    match = delivery.body.encoded.match(/(confirm\/unclaimed\?code=\w+)/)
    expect(match).to_not be_nil
    visit '/' + match.captures.first
  end


  describe 'a new user receives an invite' do

    scenario 'without a pre-existing password' do
      FindOrCreateUser.call(user_options).outputs[:user]

      visit_invite_url

      expect(page).to have_no_missing_translations
      click_on t 'contact_infos.confirm_unclaimed.you_can_now_sign_in.add_password'
      expect(page).to have_content(t :"login_signup_form.setup_your_new_password")
      # Not newflow_complete_add_password_screen: that helper assumes terms are already
      # signed and lands on profile. This user hasn't signed terms yet, so submitting
      # goes straight to the terms screen instead (same order the retired legacy flow used).
      fill_in(t(:"login_signup_form.password_label"), with: 'Passw0rd!')
      find('#login-signup-form').click
      wait_for_animations
      find('[type=submit]').click

      complete_terms_screens
      expect_back_at_app
    end

    scenario 'and resets the password' do
      arrive_from_app(do_expect: false)

      FindOrCreateUser.call(
        user_options.merge(
          password: "apassword", password_confirmation: "apassword"
        )
      )

      visit_invite_url
      click_on t 'contact_infos.confirm_unclaimed.you_can_now_sign_in.reset_password'
      expect(page).to have_content(t :"login_signup_form.enter_new_password")
      # Not newflow_complete_reset_password_screen: see comment in the sibling scenario above.
      fill_in(t(:"login_signup_form.password_label"), with: 'Passw0rd!')
      find('#login-signup-form').click
      wait_for_animations
      find('[type=submit]').click

      complete_terms_screens
      expect_back_at_app
    end
  end
end
