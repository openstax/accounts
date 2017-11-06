# coding: utf-8
require 'rails_helper'
require 'vcr_helper'

feature 'Weird cases', js: true, vcr: VCR_OPTS do

  background do
    load 'db/seeds.rb'
    create_default_application
  end

  scenario 'halt sign up before verification, log in with different account, no kaboom' do

    disable_sfdc_client

    arrive_from_app
    click_sign_up
    complete_signup_email_screen("Instructor","bob@bob.edu")

    # DO NOT complete email verification, just go and login with a different user

    expect_any_instance_of(SessionsCreate).to receive(:handle_during_login).and_call_original
    user = create_user 'other_user'
    arrive_from_app
    complete_login_username_or_email_screen 'other_user'
    complete_login_password_screen 'password'

    expect(page).not_to have_content(500)
    expect_back_at_app
  end

end
