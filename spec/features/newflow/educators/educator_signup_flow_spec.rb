require 'rails_helper'

module Newflow

  feature 'Educator signup flow', js: true do

    background { load 'db/seeds.rb' }
    before(:each) { turn_on_educator_feature_flag }

    let(:first_name) { Faker::Name.first_name  }
    let(:last_name) { Faker::Name.last_name  }
    let(:phone_number) { Faker::PhoneNumber.phone_number }
    let(:email_value) { Faker::Internet.unique.email(domain: '@rice.edu') }
    let(:password) { Faker::Internet.password(min_length: 8) }
    let(:sheerid_iframe_page_title) { 'Verify your instructor status' }
    let(:iframe_submit_button_text) { 'Verify my instructor status' }
    let(:external_app_url) { capybara_url(external_app_for_specs_path) }
    let(:return_param) { { r: external_app_for_specs_path } }
    let(:correct_pin) { EmailAddress.last.confirmation_pin }

    context 'happy path' do
      before(:each) do
        expect_any_instance_of(EducatorSignup::CreateSalesforceLead).to receive(:exec)
      end

      context 'when entering PIN code to verify email address' do
        it 'all works' do
          visit(login_path(return_param))
          click_on(I18n.t(:"login_signup_form.sign_up"))
          click_on(I18n.t(:"login_signup_form.educator"))

          # Step 1
          fill_in 'signup_first_name',	with: first_name
          fill_in 'signup_last_name',	with: last_name
          fill_in 'signup_phone_number', with: phone_number
          fill_in 'signup_email',	with: email_value
          fill_in 'signup_password',	with: password
          submit_signup_form
          screenshot!

          # Step 2
          # sends an email address confirmation email
          expect(page.current_path).to eq(educator_email_verification_form_path)
          open_email(email_value)
          capture_email!(address: email_value)
          expect(current_email).to be_truthy

          # ... with the correct PIN
          fill_in 'confirm_pin', with: correct_pin
          find('[type=submit]').click
          # ... sends you to the SheerID form
          expect(page.current_path).to eq(educator_sheerid_form_path)

          # Step 3
          expect_sheerid_iframe

          # Step 4
          expect_educator_step_4_page
          find('#signup_educator_specific_role_other').click
          fill_in('Other (please specify)', with: 'President')
          click_on('Continue')
          expect(page.current_path).to eq(signup_done_path)
          click_on('Finish')
          expect(page.current_url).to eq(external_app_url)

          # # can exit and go back to the app they came from
          # find('#exit-icon a').click
          # expect(page.current_path).to eq('/external_app_for_specs')
          # screenshot!
        end
      end

      context 'when clicking on link sent in an email to verify email address' do
        it 'all works' do
          visit(login_path(return_param))
          click_on(I18n.t(:"login_signup_form.sign_up"))
          expect(page.current_path).to eq(newflow_signup_path)
          click_on(I18n.t(:"login_signup_form.educator"))

          # Step 1
          fill_in 'signup_first_name',	with: first_name
          fill_in 'signup_last_name',	with: last_name
          fill_in 'signup_phone_number', with: phone_number
          fill_in 'signup_email',	with: email_value
          fill_in 'signup_password',	with: password
          submit_signup_form
          screenshot!

          # Step 2
          # sends an email address confirmation email
          expect(page.current_path).to eq(educator_email_verification_form_path)
          open_email(email_value)
          capture_email!(address: email_value)
          expect(current_email).to be_truthy

          # ... with a link
          verify_email_url = get_path_from_absolute_link(current_email, 'a')
          visit(verify_email_url)
          # ... which sends you to the SheerID form
          expect(page.current_path).to eq(educator_sheerid_form_path)

          # Step 3
          expect_sheerid_iframe

          # Step 4
          expect_educator_step_4_page
          find('#signup_educator_specific_role_other').click
          fill_in('Other (please specify)', with: 'President')
          click_on('Continue')
          expect(page.current_path).to eq(signup_done_path)
          click_on('Finish')
          expect(page.current_url).to eq(external_app_url)

          # # can exit and go back to the app they came from
          # find('#exit-icon a').click
          # expect(page.current_path).to eq('/external_app_for_specs')
          # screenshot!
        end
      end
    end

    context 'when educator stops signup flow, logs out, after completing step 2' do
      let(:sheerid_verification) do
        FactoryBot.create(:sheerid_verification, email: email_value)
      end

      it 'redirects them to continue signup flow (step 3) after logging in' do
        skip 'because it only fails in Travis but works locally and locally testing'

        visit(login_path(return_param))
        click_on(I18n.t(:"login_signup_form.sign_up"))
        click_on(I18n.t(:"login_signup_form.educator"))

        # Step 1
        fill_in 'signup_first_name',	with: first_name
        fill_in 'signup_last_name',	with: last_name
        fill_in 'signup_phone_number', with: phone_number
        fill_in 'signup_email',	with: email_value
        fill_in 'signup_password',	with: password
        submit_signup_form
        screenshot!

        # Step 2
        # sends an email address confirmation email
        expect(page.current_path).to eq(educator_email_verification_form_path)
        open_email(email_value)
        capture_email!(address: email_value)
        expect(current_email).to be_truthy
        # ... with the correct PIN
        fill_in 'confirm_pin', with: correct_pin
        find('[type=submit]').click
        # ... sends you to the SheerID form
        expect(page.current_path).to eq(educator_sheerid_form_path)

        # LOG OUT
        visit(signout_path)
        expect(page).to have_current_path(newflow_login_path)

        # LOG IN
        visit(login_path(return_param))
        newflow_log_in_user(email_value, password)

        # Step 3
        expect_sheerid_iframe
        simulate_step_3_instant_verification(User.last, sheerid_verification.verification_id)

        # Step 4
        expect_educator_step_4_page
        find('#signup_educator_specific_role_other').click
        fill_in('Other (please specify)', with: 'President')
        click_on('Continue')
        expect(page.current_path).to eq(signup_done_path)
        click_on('Finish')
        wait_for_ajax
        expect(page.current_url).to eq(external_app_url)

        # # can exit and go back to the app they came from
        # find('#exit-icon a').click
        # expect(page.current_path).to eq('/external_app_for_specs')
        # screenshot!
      end
    end

    context 'when educator stops signup flow, logs out, after completing step 3' do
      it 'redirects them to continue signup flow (step 4) after logging in'
    end

    context 'when legacy educator wants to request faculty verification' do
      before(:each) do
        educator.update(
          is_newflow: false,
          role: User::INSTRUCTOR_ROLE,
          first_name: first_name,
          last_name: last_name
        )

        visit(login_path)
        newflow_log_in_user(email_value, password)
        visit faculty_access_apply_path(r: capybara_url(external_app_for_specs_path))
      end

      let!(:educator) { create_newflow_user(email_value, password) }
      let(:email_value) { 'user@openstax.org' }
      let(:password) { 'password' }

      context 'with faculty status as no_faculty_info' do
        it 'sends them to step 3 — SheerID iframe' do
          expect_sheerid_iframe
        end
      end

      context 'with faculty status as rejected' do
        it 'sends them to step 4 — Educator Profile Form' do
          expect_educator_step_4_page
        end
      end
    end

    context 'when educators have been rejected by SheerID one or more times' do
      context 'and have been in the pending faculty status step for more than 4 days' do
        it 'will send them through the CS verification process (modified step 4)'
      end
    end

    context 'when educator uses the browser\'s built-in back-arrow' do
      context 'after completing step 1' do
        it 'sends them back to the next, correct, step'
      end

      context 'after completing step 2' do
        it 'sends them back to the next, correct, step'
      end

      context 'after completing step 3' do
        it 'sends them back to the next, correct, step'
      end

      context 'after completing step 4' do
        it 'sends them back to the next, correct, step'
      end
    end

  end

end
