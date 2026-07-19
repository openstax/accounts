require 'rails_helper'

module Newflow

  feature 'Staff signup flow', js: true do

    background { load 'db/seeds.rb' }
    before(:each) { turn_on_educator_feature_flag }

    let(:first_name) { Faker::Name.first_name }
    let(:last_name) { Faker::Name.last_name }
    let(:phone_number) { Faker::PhoneNumber.phone_number }
    let(:email_value) { Faker::Internet.unique.email(domain: '@rice.edu') }
    let(:password) { Faker::Internet.password(min_length: 8) }

    def sign_up_and_verify_as_staff
      visit(newflow_signup_path)
      newflow_click_sign_up(role: 'staff')
      expect(page).to have_current_path(staff_signup_path)

      fill_in 'signup_first_name', with: first_name
      fill_in 'signup_last_name', with: last_name
      fill_in 'signup_phone_number', with: phone_number
      fill_in 'signup_email', with: email_value
      fill_in 'signup_password', with: password
      submit_signup_form

      perform_enqueued_jobs

      expect(page).to have_current_path(staff_email_verification_form_path)
      open_email(email_value)
      capture_email!(address: email_value)
      expect(current_email).to be_truthy

      correct_pin = EmailAddress.find_by!(value: email_value).confirmation_pin
      fill_in('confirm_pin', with: correct_pin)
      wait_for_ajax
      wait_for_animations
      click_on(I18n.t(:"login_signup_form.confirm_my_account_button"))
      wait_for_ajax
      wait_for_animations
    end

    context 'happy path' do
      it 'signs up as staff, verifies email by PIN, skips SheerID, and lands on signup done' do
        sign_up_and_verify_as_staff
        expect(EmailAddress.verified.count).to eq(1)

        # Step 3 - staff skip SheerID entirely and land on "Tell us about your work"
        expect(page).to have_current_path(staff_details_form_path)
        expect(page).to have_content(I18n.t(:"staff_details_form.header"))

        find('#signup_staff_role_librarian').click
        fill_in('signup[school_name]', with: 'Rice University')
        fill_in('signup[num_learners_supported]', with: '400')

        find('#signup_form_submit_button').click
        wait_for_ajax
        wait_for_animations

        expect(page).to have_current_path(signup_done_path)

        user = User.find_by!(role: 'librarian')
        expect(user.other_role_name).to eq('Librarian')
        expect(user.is_profile_complete?).to be true
        expect(user.sheerid_verification_id).to be_blank
        expect(user.how_many_students).to eq('400')
      end
    end

    context 'the "Other" role' do
      it 'requires the free-text field before completing' do
        sign_up_and_verify_as_staff
        expect(page).to have_current_path(staff_details_form_path)

        find('#signup_staff_role_other').click
        expect(page).to have_field(I18n.t(:"staff_details_form.other_please_specify"))
        fill_in('signup[school_name]', with: 'Rice University')
        fill_in('signup[num_learners_supported]', with: '10')
        find('#signup_form_submit_button').click
        wait_for_ajax
        wait_for_animations

        # No redirect on validation failure, so the browser is left on the
        # POST target with the form (and its error) re-rendered.
        expect(page).to have_current_path(staff_complete_profile_path)
        expect(page).to have_field(I18n.t(:"staff_details_form.other_please_specify"))

        fill_in(I18n.t(:"staff_details_form.other_please_specify"), with: 'Grant writer')
        find('#signup_form_submit_button').click
        wait_for_ajax
        wait_for_animations

        expect(page).to have_current_path(signup_done_path)
      end
    end
  end
end
