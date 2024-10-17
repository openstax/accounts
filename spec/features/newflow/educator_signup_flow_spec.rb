require 'rails_helper'
#require 'byebug'

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

    context 'happy path' do
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

          perform_enqueued_jobs

          # Step 2
          # sends an email address confirmation email
          expect(page.current_path).to eq(educator_email_verification_form_path)
          open_email(email_value)
          capture_email!(address: email_value)
          expect(current_email).to be_truthy

          # ... with the correct PIN
          expect(EmailAddress.verified.count).to eq(0)
          correct_pin = EmailAddress.find_by!(value: email_value).confirmation_pin
          fill_in('confirm_pin', with: correct_pin)
          wait_for_ajax
          wait_for_animations
          click_on(I18n.t(:"login_signup_form.confirm_my_account_button"))
          wait_for_ajax
          wait_for_animations
          expect(page).to_not have_content(I18n.t(:"login_signup_form.confirm_my_account_button"))
          expect(EmailAddress.verified.count).to eq(1)

          # Step 3
          expect_sheerid_iframe

          # Step 4
          expect_educator_step_4_page
          select_educator_role('other')
          fill_in('Other (please specify)', with: 'President')
          find('#signup_form_submit_button').click
          visit(signup_done_path)
          expect(page.current_path).to eq(signup_done_path).or eq(educator_pending_cs_verification_path)
          click_on('Finish')
          expect(page.current_url).to eq(external_app_url)
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

          perform_enqueued_jobs

          # Step 2
          # sends an email address confirmation email
          expect(page.current_path).to eq(educator_email_verification_form_path)
          open_email(email_value)
          capture_email!(address: email_value)
          expect(current_email).to be_truthy

          # ... with a link
          verify_email_url = get_path_from_absolute_link(current_email, '#confirm-link')
          visit(verify_email_url)

          # Step 3
          expect_sheerid_iframe

          # Step 4
          expect_educator_step_4_page
          find('#signup_educator_specific_role_other').click
          fill_in(I18n.t(:"educator_profile_form.other_please_specify"), with: 'President')
          click_on('Continue')
          visit(signup_done_path)
          expect(page.current_path).to eq(signup_done_path)
          click_on('Finish')
          expect(page.current_url).to eq(external_app_url)
        end
      end
    end

    context 'when educator has not verified their only email address' do
      let!(:user) { FactoryBot.create(:user, state: User::UNVERIFIED, role: User::INSTRUCTOR_ROLE) }
      let!(:email_address) { FactoryBot.create(:email_address, user: user, verified: false) }
      let!(:identity) { FactoryBot.create(:identity, user: user, password: password) }
      let!(:password) { 'password' }

      it 'allows the educator to log in and redirects them to the email verification form' do
        visit(newflow_login_path)
        fill_in('login_form_email', with: email_address.value)
        fill_in('login_form_password', with: password)
        find('[type=submit]').click
        expect(page.current_path).to match(educator_email_verification_form_path)
      end

      it 'allows the educator to reset their password' do
        visit(newflow_login_path)
        complete_newflow_log_in_screen(email_address.value, 'WRONGpassword')
        find('[id=forgot-password-link]').click
        expect(page.current_path).to eq(forgot_password_form_path)
        expect(find('#forgot_password_form_email')['value']).to eq(email_address.value)
        screenshot!
        click_on(I18n.t(:"login_signup_form.reset_my_password_button"))
        screenshot!
      end
    end

    context 'user interface' do
      before { mock_current_user(user) }

      let(:user) do
        FactoryBot.create(
          :user, is_newflow: true, role: User::INSTRUCTOR_ROLE,
          is_profile_complete: false, sheerid_verification_id: Faker::Alphanumeric.alphanumeric
        )
      end

      context 'step 4' do
        before do
          visit(educator_profile_form_path)
          expect_educator_step_4_page
          select_educator_role('instructor')
          find('#signup_who_chooses_books_instructor').click
        end

        context 'label for books list' do
          context 'when already using openstax book(s)' do
            before do
              find('#signup_using_openstax_how_as_primary').click
            end

            it 'shows "Books used"' do
              expect(page).to have_text(I18n.t(:"educator_profile_form.books_used"))
            end
          end

          context 'when NOT yet using openstax book(s)' do
            before do
              find('#signup_using_openstax_how_as_recommending').click
            end

            it 'shows "Books of interest"' do
              expect(page).to have_text(I18n.t(:"educator_profile_form.books_of_interest"))
            end
          end
        end
      end
    end

    context 'when educator stops signup flow, logs out, after completing step 2' do
      let(:sheerid_verification) do
        FactoryBot.create(:sheerid_verification, email: email_value)
      end

      it 'redirects them to continue signup flow (step 3) after logging in' do
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

        perform_enqueued_jobs

        # Step 2
        # sends an email address confirmation email
        expect(page.current_path).to eq(educator_email_verification_form_path)
        open_email(email_value)
        capture_email!(address: email_value)
        expect(current_email).to be_truthy
        # ... with the correct PIN
        correct_pin = EmailAddress.find_by!(value: email_value).confirmation_pin
        fill_in('confirm_pin', with: correct_pin)
        wait_for_ajax
        wait_for_animations
        #expect(page).to have_content(I18n.t(:"login_signup_form.confirm_my_account_button"))
        click_on(I18n.t(:"login_signup_form.confirm_my_account_button"))
        #expect(page).to_not have_content(I18n.t(:"login_signup_form.confirm_my_account_button"))
        wait_for_ajax
        wait_for_animations
        expect(EmailAddress.verified.count).to eq(1)

        wait_for_ajax
        wait_for_animations
        # ... sends you to the SheerID form
        expect(page).to have_current_path(educator_sheerid_form_path)

        # LOG OUT
        visit(signout_path)
        expect(page).to have_current_path(newflow_login_path)

        # LOG IN
        visit(login_path(return_param))
        complete_newflow_log_in_screen(email_value, password)

        # Step 3
        expect_sheerid_iframe
        click_on('Stuck? Click here to skip instant verification.')

        # Step 4
        expect_educator_step_4_page
        fill_in('signup[school_name]', with: 'Rice University')
        find('#signup_educator_specific_role_other').click
        expect(page).to have_text(I18n.t(:"educator_profile_form.other_please_specify"))
        fill_in(I18n.t(:"educator_profile_form.other_please_specify"), with: 'President')
        click_on('Continue')
        visit(educator_pending_cs_verification_path)
        expect(page.current_path).to eq(educator_pending_cs_verification_path)
        click_on('Finish')
        wait_for_ajax
        expect(page.current_url).to eq(external_app_url)
      end
    end
  end
end
