require 'rails_helper'

feature 'User claims an unclaimed account' do
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
    delivery = ActionMailer::Base.deliveries.last
    match = delivery.body.encoded.match(/(confirm\/unclaimed\?code=\w+)/)
    expect(match).to_not be_nil
    visit '/' + match.captures.first
  end


  describe 'a new user receives an invite' do

    scenario 'without a pre-existing password' do
      FindOrCreateUnclaimedUser.call(user_options).outputs[:user]

      visit_invite_url

      expect(page).to have_no_missing_translations
      click_on t 'contact_infos.confirm_unclaimed.you_can_now_sign_in.add_password'
      expect(page).to have_content(t :"identities.add.page_heading")
      complete_add_password_screen

      complete_add_password_success_screen
      complete_terms_screens
      expect_back_at_app
    end

    scenario 'and resets the password' do
      arrive_from_app(do_expect: false)

      FindOrCreateUnclaimedUser.call(
        user_options.merge(
          password: "apassword", password_confirmation: "apassword"
        )
      )

      visit_invite_url
      click_on t 'contact_infos.confirm_unclaimed.you_can_now_sign_in.reset_password'
      expect(page).to have_content(t :"identities.reset.page_heading")
      complete_reset_password_screen
      complete_reset_password_success_screen
      complete_terms_screens
      expect_back_at_app
    end
  end
end
