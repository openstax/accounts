require 'rails_helper'

module Newflow
  feature 'Lifelong learner signup flow', js: true do
    before do
      disable_sfdc_client
      load 'db/seeds.rb'
    end

    let(:email) do
      Faker::Internet::email
    end

    let(:password) do
      Faker::Internet.password(min_length: 8)
    end

    context 'signup happy path' do
      before do
        visit newflow_signup_path
        click_on I18n.t(:"login_signup_form.learner_skip_the_questions")
        expect(page).to have_current_path newflow_signup_learner_path
        fill_in 'signup_email', with: email
        fill_in 'signup_password', with: password
        click_button I18n.t(:"login_signup_form.learner_create_account_button")
        expect(page).to have_current_path learner_email_verification_form_path

        screenshot!

        perform_enqueued_jobs

        open_email email
        capture_email!(address: email)
        expect(current_email).to be_truthy
      end

      example 'verify email by entering PIN sent in the email lands on the learner welcome screen' do
        pin = current_email.find('#pin').text
        fill_in('confirm_pin', with: pin)
        screenshot!
        click_on('commit')

        expect(page).to have_current_path(learner_welcome_path)
        # learner_welcome_header is upper-cased via CSS text-transform, so match
        # case-insensitively rather than against the literal (mixed-case) copy.
        expect(page).to have_text(/#{I18n.t(:"login_signup_form.learner_welcome_header")}/i)
        expect(page).to have_text(I18n.t(:"login_signup_form.learner_popular_title"))
        screenshot!
      end
    end

    context 'not happy path' do
      example 'blank email and password' do
        visit newflow_signup_learner_path
        click_button I18n.t(:"login_signup_form.learner_create_account_button")
        screenshot!
        [:email, :password].each do |field|
          expect(page).to have_text(I18n.t(:"login_signup_form.#{field}_is_blank"))
        end
      end
    end

    it 'tags the resulting account as a self-learner, not a student' do
      visit newflow_signup_learner_path
      fill_in 'signup_email', with: email
      fill_in 'signup_password', with: password
      click_button I18n.t(:"login_signup_form.learner_create_account_button")
      # wait for the redirect so the DB write below isn't racing the request
      expect(page).to have_current_path(learner_email_verification_form_path)

      user = User.find_by!(role: 'self_learner')
      expect(user).not_to be_student
      expect(user.first_name).to be_blank
    end
  end
end
