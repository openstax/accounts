require 'rails_helper'

RSpec.feature 'Educator signup flow', js: true do

  background { load 'db/seeds.rb' }

  let(:first_name) { Faker::Name.first_name  }
  let(:last_name) { Faker::Name.last_name  }
  let(:phone_number) { Faker::PhoneNumber.phone_number }
  let(:email_value) { Faker::Internet.unique.email(domain: '@rice.edu') }
  let(:password) { Faker::Internet.password(min_length: 8) }
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

        # Step 2
        # sends an email address confirmation email
        expect(page.current_path).to eq(verify_email_by_pin_form_path)
        open_email(email_value)
        capture_email!(address: email_value)
        expect(current_email).to be_truthy

        # ... with the correct PIN
        expect(EmailAddress.verified.count).to eq(0)
        email_address = EmailAddress.find_by(value: email_value)
        signing_up_user = email_address.user
        correct_pin = email_address.confirmation_pin
        expect(signing_up_user.faculty_status).to eq('incomplete_signup')
        fill_in('confirm_pin', with: correct_pin)
        click_on(I18n.t(:"login_signup_form.confirm_my_account_button"))
        wait_for_ajax
        wait_for_animations
        expect(page).to_not have_content(I18n.t(:"login_signup_form.confirm_my_account_button"))
        expect(EmailAddress.verified.count).to eq(1)

        # Step 3
        expect_sheerid_iframe

        # Step 4
        visit(profile_form_path)
        expect(page.current_path).to eq(profile_form_path)
        find("#signup_educator_specific_role_other").click
        fill_in('Other (please specify)', with: 'President')
        find('[type="submit"]').click
        expect(page.current_path).to eq(signup_done_path).or eq('/signup/educator/pending_cs_verification')
        expect(signing_up_user.faculty_status).to eq('pending_faculty')
        click_on('Finish')
        expect(page.current_url).to eq(external_app_url)
      end
    end

    context 'when clicking on link sent in an email to verify email address' do
      it 'all works' do
        visit(login_path(return_param))
        click_on(I18n.t(:"login_signup_form.sign_up"))
        expect(page.current_path).to eq(signup_path)
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
        email_address   = EmailAddress.find_by(value: email_value)
        signing_up_user = email_address.user

        expect(page.current_path).to eq(verify_email_by_pin_form_path)
        open_email(email_value)
        capture_email!(address: email_value)
        expect(current_email).to be_truthy
        expect(signing_up_user.faculty_status).to eq('incomplete_signup')

        # ... with a link
        verify_email_url = get_path_from_absolute_link(current_email, 'a')
        visit(verify_email_url)

        # Step 3
        expect_sheerid_iframe

        # Step 4
        visit(profile_form_path)
        expect(page.current_path).to eq(profile_form_path)
        find('#signup_educator_specific_role_other').click
        fill_in(I18n.t(:"educator_profile_form.other_please_specify"), with: 'President')
        click_on('Continue')
        expect(page.current_path).to eq('/signup/educator/pending_cs_verification')
        expect(signing_up_user.faculty_status).to eq('pending_faculty')
        click_on('Finish')
        expect(page.current_url).to eq(external_app_url)
      end
    end
  end

  context 'when educator has not verified their only email address' do
    let!(:user) { FactoryBot.create(:user, state: 'unverified', role: 'instructor', faculty_status: 'incomplete_signup') }
    let!(:email_address) { FactoryBot.create(:email_address, user: user, verified: false) }
    let!(:identity) { FactoryBot.create(:identity, user: user, password: password) }
    let!(:password) { 'password' }

    it 'allows the educator to log in and redirects them to the email verification form' do
      visit(login_path)
      fill_in('login_form_email', with: email_address.value)
      fill_in('login_form_password', with: password)
      find('[type=submit]').click
      expect(page.current_path).to match(verify_email_by_pin_form_path)
    end

    it 'allows the educator to reset their password' do
      visit(login_path)
      log_in_user(email_address.value, 'WRONGpassword')
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
        :user, :terms_agreed, role: User::INSTRUCTOR_ROLE,
        is_profile_complete: false, sheerid_verification_id: Faker::Alphanumeric.alphanumeric
      )
    end

    context 'step 4' do
      before do
        visit(profile_form_path)
        expect(page.current_path).to eq(profile_form_path)
        find("#signup_educator_specific_role_instructor").click
        find('#signup_who_chooses_books_instructor').click
        fill_in(I18n.t(:"educator_profile_form.num_students_taught"), with: 30)
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

      # Step 2
      # sends an email address confirmation email
      expect(page.current_path).to eq(verify_email_by_pin_form_path)
      open_email(email_value)
      capture_email!(address: email_value)
      expect(current_email).to be_truthy
      # ... with the correct PIN
      correct_pin = EmailAddress.find_by!(value: email_value).confirmation_pin
      fill_in('confirm_pin', with: correct_pin)
      click_on(I18n.t(:"login_signup_form.confirm_my_account_button"))
      wait_for_ajax
      wait_for_animations

      wait_for_ajax
      wait_for_animations
      # ... sends you to the SheerID form
      expect(page).to have_current_path(sheerid_form_path)

      # LOG OUT
      visit(logout_path)
      expect(page).to have_current_path(login_path)

      # LOG IN
      visit(login_path(return_param))
      log_in_user(email_value, password)

      # Step 3
      expect_sheerid_iframe
      # SheeridWebhook.call(user: User.last, verification_id: sheerid_verification.verification_id)


      # Step 4
      visit(profile_form_path)
      expect(page.current_path).to eq(profile_form_path)
      find('#signup_educator_specific_role_other').click
      expect(page).to have_text(I18n.t(:"educator_profile_form.other_please_specify"))
      fill_in(I18n.t(:"educator_profile_form.other_please_specify"), with: 'President')
      click_on('Continue')
      expect(page.current_path).to eq('/signup/educator/pending_cs_verification')
      click_on('Finish')
      wait_for_ajax
      expect(page.current_url).to eq(external_app_url)
    end
  end

  def expect_sheerid_iframe
    within_frame do
      expect(page).to have_text('Verify your instructor status')
      expect(page.find('#sid-country')[:value]).to have_text('United States', exact: false)
      expect(page.find('#sid-teacher-school')[:value]).to be_blank
      expect(page.find('#sid-first-name')[:value]).to have_text(first_name)
      expect(page.find('#sid-last-name')[:value]).to have_text(last_name)
      expect(page.find('#sid-email')[:value]).to have_text(email_value)
      expect(page).to have_text('Can\'t find your country in the list? Click here.')
      expect(page).to have_text('Can\'t find your school in the list? Click here.')
      expect(page).to have_text('Verify my instructor status')
      screenshot!
    end
  end
end
