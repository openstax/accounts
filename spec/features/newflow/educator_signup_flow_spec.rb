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
    let(:return_param) { { r: external_app_for_specs_path } }

    context 'happy path' do
      context 'when entering PIN code to verify email address' do
        it 'all works' do
          visit(login_path(return_param))
          click_on(I18n.t(:"login_signup_form.sign_up"))
          find('.join-as__option--educator').click

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
          expect(page).to have_current_path(educator_email_verification_form_path)
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
          # "Other staff" now routes to the staff questionnaire (redesign):
          # complete signup there instead of the old inline free-text field.
          expect(page).to have_current_path(staff_details_form_path)
          find('#signup_staff_role_other').click
          fill_in(I18n.t(:"staff_details_form.other_please_specify"), with: 'President')
          fill_in('signup[school_name]', with: 'Rice University')
          fill_in('signup[num_learners_supported]', with: '10')
          find('#signup_form_submit_button').click
          wait_for_ajax
          visit(signup_done_path)
          expect(page).to have_current_path(signup_done_path)
        end
      end

      context 'when clicking on link sent in an email to verify email address' do
        it 'all works' do
          visit(login_path(return_param))
          click_on(I18n.t(:"login_signup_form.sign_up"))
          expect(page).to have_current_path(newflow_signup_path)
          find('.join-as__option--educator').click

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
          expect(page).to have_current_path(educator_email_verification_form_path)
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
          # "Other staff" now routes to the staff questionnaire (redesign):
          # complete signup there instead of the old inline free-text field.
          expect(page).to have_current_path(staff_details_form_path)
          find('#signup_staff_role_other').click
          fill_in(I18n.t(:"staff_details_form.other_please_specify"), with: 'President')
          fill_in('signup[school_name]', with: 'Rice University')
          fill_in('signup[num_learners_supported]', with: '10')
          find('#signup_form_submit_button').click
          wait_for_ajax
          visit(signup_done_path)
          expect(page).to have_current_path(signup_done_path)
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
        complete_newflow_log_in_screen(email_address.value, password)
        expect(page).to have_current_path(educator_email_verification_form_path)
      end

      it 'allows the educator to reset their password' do
        visit(newflow_login_path)
        complete_newflow_log_in_screen(email_address.value, 'WRONGpassword')
        find('[id=forgot-password-link]').click
        expect(page).to have_current_path(forgot_password_form_path)
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
        end

        context 'label for books list' do
          context 'when already using openstax book(s)' do
            before do
              find('#signup_using_openstax_how_as_primary').click
            end

            it 'shows the book selection label' do
              expect(page).to have_text(I18n.t(:"educator_profile_form.books_used"))
            end
          end

          context 'when NOT yet using openstax book(s)' do
            before do
              find('#signup_using_openstax_how_as_recommending').click
            end

            it 'shows the book selection label' do
              expect(page).to have_text(I18n.t(:"educator_profile_form.books_of_interest"))
            end
          end
        end
      end
    end

    context 'DATA-301: expected start semester' do
      before { mock_current_user(user) }

      let(:user) do
        FactoryBot.create(
          :user, is_newflow: true, role: User::INSTRUCTOR_ROLE,
          is_profile_complete: false, sheerid_verification_id: Faker::Alphanumeric.alphanumeric
        )
      end

      context 'when the feature flag is on' do
        before do
          Settings::FeatureFlags.expected_start_semester_enabled = true
        end

        after do
          Settings::FeatureFlags.expected_start_semester_enabled = false
        end

        it 'shows the dropdown when as_primary is selected and retains the selected value' do
          visit(educator_profile_form_path)
          expect_educator_step_4_page
          select_educator_role('instructor')
          find('#signup_using_openstax_how_as_primary').click

          expect(page).to have_selector('.expected-start-semester', visible: true)

          select 'Next semester', from: 'signup_expected_start_semester'

          expect(find('#signup_expected_start_semester').value).to eq('next_semester')
        end

        it 'hides the dropdown and clears the value when as_future is selected after as_primary' do
          visit(educator_profile_form_path)
          expect_educator_step_4_page
          select_educator_role('instructor')
          find('#signup_using_openstax_how_as_primary').click

          select 'Next semester', from: 'signup_expected_start_semester'
          expect(find('#signup_expected_start_semester').value).to eq('next_semester')

          find('#signup_using_openstax_how_as_future').click

          expect(page).to have_no_selector('.expected-start-semester', visible: true)
          expect(find('#signup_expected_start_semester', visible: false).value).to eq('')
        end

        it 'shows the dropdown when as_recommending is selected' do
          visit(educator_profile_form_path)
          expect_educator_step_4_page
          select_educator_role('instructor')
          find('#signup_using_openstax_how_as_recommending').click

          expect(page).to have_selector('.expected-start-semester', visible: true)
        end
      end

      context 'when the feature flag is off' do
        before do
          Settings::FeatureFlags.expected_start_semester_enabled = false
        end

        it 'does not render the dropdown' do
          visit(educator_profile_form_path)
          expect_educator_step_4_page
          expect(page).to have_no_selector('.expected-start-semester')
          expect(page).to have_no_content(I18n.t(:"educator_profile_form.expected_start_semester"))
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
        find('.join-as__option--educator').click

        # Step 1
        fill_in 'signup_first_name',	with: first_name
        fill_in 'signup_last_name',	with: last_name
        fill_in 'signup_phone_number', with: phone_number
        fill_in 'signup_email',	with: email_value
        fill_in 'signup_password',	with: password
        submit_signup_form
        expect(page).to have_current_path(educator_email_verification_form_path)

        screenshot!

        perform_enqueued_jobs

        # Step 2
        # sends an email address confirmation email
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
        click_on(I18n.t(:"login_signup_form.sheerid_manual_review_link_text"))

        # Step 4
        expect_educator_step_4_page
        fill_in('signup[school_name]', with: 'Rice University')
        # Administrator stays inline on the educator form ("Other staff" now
        # routes to the staff questionnaire); use it here so this spec keeps
        # covering the educator pending-CS-verification path.
        find('#signup_educator_specific_role_administrator').click
        find('#signup_using_openstax_how_as_future').click
        click_on(I18n.t(:"educator_profile_form.finish_button"))
        visit(educator_pending_cs_verification_path)
        expect(page).to have_current_path(educator_pending_cs_verification_path)
        click_on('Finish')
        wait_for_ajax
        expect(page).to have_current_path(external_app_for_specs_path)
      end
    end

    context 'school-email gate at the SheerID step' do
      # Simulates an instructor whose only email on file is personal - e.g. a
      # Google-signup instructor, whose account has no manually-entered email.
      let(:personal_email) { Faker::Internet.unique.email(domain: '@gmail.com') }
      let(:school_email) { Faker::Internet.unique.email(domain: '@rice.edu') }

      before do
        user = create_newflow_user(personal_email, password, true, nil, 'instructor')
        user.update!(is_profile_complete: false)
      end

      it 'shows the gate, and adding a school email proceeds to a pre-filled SheerID widget' do
        visit(login_path(return_param))
        complete_newflow_log_in_screen(personal_email, password)

        # Step 3 - gate shown because the on-file email looks personal
        expect(page).to have_text(I18n.t(:"login_signup_form.school_email_gate_title"))
        expect(page).to have_text(personal_email)

        fill_in(I18n.t(:"login_signup_form.school_issued_email_label"), with: school_email)
        click_on(I18n.t(:"login_signup_form.continue_button"))
        perform_enqueued_jobs

        expect(page).to have_current_path(educator_sheerid_form_path)
        expect(page).to_not have_text(I18n.t(:"login_signup_form.school_email_gate_title"))
        expect(EmailAddress.find_by(value: school_email)).to be_present

        within_frame do
          expect(page.find('#sid-email')[:value]).to have_text(school_email)
        end
      end

      it 'lets the user proceed with their current (personal) email anyway' do
        visit(login_path(return_param))
        complete_newflow_log_in_screen(personal_email, password)

        expect(page).to have_text(I18n.t(:"login_signup_form.school_email_gate_title"))
        click_on(I18n.t(:"login_signup_form.use_current_email_anyway"))

        expect(page).to have_current_path(educator_sheerid_form_path)
        expect(page).to_not have_text(I18n.t(:"login_signup_form.school_email_gate_title"))

        within_frame do
          expect(page.find('#sid-email')[:value]).to have_text(personal_email)
        end
      end
    end

    context 'when the signup email already looks like a school email' do
      let(:school_email_on_file) { Faker::Internet.unique.email(domain: '@rice.edu') }

      before do
        user = create_newflow_user(school_email_on_file, password, true, nil, 'instructor')
        user.update!(is_profile_complete: false)
      end

      it 'goes straight to the SheerID widget without the gate' do
        visit(login_path(return_param))
        complete_newflow_log_in_screen(school_email_on_file, password)

        expect(page).to_not have_text(I18n.t(:"login_signup_form.school_email_gate_title"))
        within_frame do
          expect(page.find('#sid-email')[:value]).to have_text(school_email_on_file)
        end
      end
    end
  end
end
