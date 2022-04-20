require 'rails_helper'

feature 'Educator signup flow', js: true do

  background { load 'db/seeds.rb' }
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
        click_on(I18n.t(:'login_signup_form.sign_up'))
        click_on(I18n.t(:'login_signup_form.educator'))

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
        expect(EmailAddress.verified.count).to eq(0)
        correct_pin = EmailAddress.find_by!(value: email_value).confirmation_pin
        fill_in('confirm_pin', with: correct_pin)
        wait_for_ajax
        wait_for_animations
        click_on(I18n.t(:'login_signup_form.confirm_my_account_button'))
        wait_for_ajax
        wait_for_animations
        expect(page).to_not have_content(I18n.t(:'login_signup_form.confirm_my_account_button'))
        expect(EmailAddress.verified.count).to eq(1)

        # Step 3
        expect_sheerid_iframe
        EducatorSignup::VerifyEducator.call(user: User.last, verification_id: sheerid_verification.verification_id)

        # Step 4
        visit(educator_profile_form_path)
        expect(page.current_path).to eq(educator_profile_form_path)
        find('#signup_educator_specific_role_other').click
        fill_in(I18n.t(:'educator_profile_form.other_please_specify'), with: 'President')
        click_on('Continue')
        #expect(page.current_path).to eq(signup_done_path)
        #click_on('Finish')
        #expect(page.current_url).to eq(external_app_url)
      end
    end

    context 'when educator stops signup flow, logs out, after completing step 3' do
      it 'redirects them to continue signup flow (step 4) after logging in'
    end

    context 'when legacy educator wants to request faculty verification' do
      #TODO:
      # skipping this spec, this entire feature spec is poorly written and should be refactored once
      # all the newflow methods are fixed. Manually tested this expected redirect works. MV 8Jun22
      pending("These routes no longer exist and are being redirected in routes.rb - evaluate if this is even still needed")
      before(:each) do
        educator.update(
          role: User::INSTRUCTOR_ROLE,
          first_name: first_name,
          last_name: last_name
        )

        visit(login_path)
        log_in_user(email_value, password)
        visit("/faculty_access/apply?r=#{capybara_url(external_app_for_specs_path)}")
      end

      let!(:educator) { create_newflow_user(email_value, password) }
      let(:email_value) { 'user@openstax.org' }
      let(:password) { 'password' }

      context 'with faculty status as no_faculty_info' do
        xit 'sends them to step 3 SheerID iframe' do
          expect_sheerid_iframe
        end
      end

      context 'with faculty status as rejected' do
        xit 'sends them to step 4 Educator Profile Form' do
          visit(educator_profile_form_path)
          expect(page.current_path).to eq(educator_profile_form_path)
        end

        it 'shows a school name field'

        it 'shows a school-issued email field'
      end
    end

    context 'when educators have been rejected by SheerID one or more times' do
      context 'and have been in the pending faculty status step for more than 4 days' do
        it 'will send them through the CS verification process (modified step 4)'
      end
    end
  end

  context 'when educator has not verified their only email address' do
    let!(:user) { FactoryBot.create(:user, state: User::UNVERIFIED, role: User::INSTRUCTOR_ROLE) }
    let!(:email_address) { FactoryBot.create(:email_address, user: user, verified: false) }
    let!(:identity) { FactoryBot.create(:identity, user: user, password: password) }
    let!(:password) { 'password' }

    xit 'allows the educator to log in and redirects them to the email verification form' do
      visit(login_path)
      fill_in('login_form_email', with: email_address.value)
      fill_in('login_form_password', with: password)
      find('[type=submit]').click
      expect(page.current_path).to match(educator_email_verification_form_path)
    end

    xit 'allows the educator to reset their password' do
      visit(login_path)
      log_in_user(email_address.value, 'WRONGpassword')
      find('[id=forgot-password-link]').click
      #click_on(I18n.t(:"login_signup_form.forgot_password"))
      expect(page.current_path).to eq(forgot_password_form_path)
      expect(find('#forgot_password_form_email')['value']).to eq(email_address.value)
      screenshot!
      click_on(I18n.t(:'login_signup_form.reset_my_password_button'))
      screenshot!
    end
  end

  context 'user interface' do
    before { mock_current_user(user) }

    let(:user) do
      FactoryBot.create(
        :user, role: User::INSTRUCTOR_ROLE,
        is_profile_complete: false, sheerid_verification_id: Faker::Alphanumeric.alphanumeric
      )
    end

    context 'step 4' do
      before do
        visit(educator_profile_form_path)
        find("#signup_educator_specific_role_instructor").click
        find('#signup_who_chooses_books_instructor').click
        fill_in(I18n.t(:'educator_profile_form.num_students_taught'), with: 30)
      end

      context 'label for books list' do
        context 'when already using openstax book(s)' do
          before do
            find('#signup_using_openstax_how_as_primary').click
          end

          it 'shows "Books used"' do
            expect(page).to have_text(I18n.t(:'educator_profile_form.books_used'))
          end
        end

        context 'when NOT yet using openstax book(s)' do
          before do
            find('#signup_using_openstax_how_as_recommending').click
          end

          it 'shows "Books of interest"' do
            expect(page).to have_text(I18n.t(:'educator_profile_form.books_of_interest'))
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
      skip 'because it only fails in Travis but works locally and locally testing'

      visit(login_path(return_param))
      click_on(I18n.t(:'login_signup_form.sign_up'))
      click_on(I18n.t(:'login_signup_form.educator'))

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
      correct_pin = EmailAddress.find_by!(value: email_value).confirmation_pin
      fill_in('confirm_pin', with: correct_pin)
      wait_for_ajax
      wait_for_animations
      expect(page).to have_content(correct_pin)
      expect(page).to have_content(I18n.t(:'login_signup_form.confirm_my_account_button'))
      click_on(I18n.t(:'login_signup_form.confirm_my_account_button'))
      expect(page).to_not have_content(I18n.t(:'login_signup_form.confirm_my_account_button'))
      wait_for_ajax
      wait_for_animations
      expect(EmailAddress.verified.count).to eq(1)

      wait_for_ajax
      wait_for_animations
      # ... sends you to the SheerID form
      expect(page).to have_current_path(educator_sheerid_form_path)

      # LOG OUT
      visit(signout_path)
      expect(page).to have_current_path(login_path)

      # LOG IN
      visit(login_path(return_param))
      log_in_user(email_value, password)

      # Step 3
      expect_sheerid_iframe
      EducatorSignup::VerifyEducator.call(user: User.last, verification_id: sheerid_verification.verification_id)

      # Step 4
      expect_educator_step_4_page
      find('#signup_educator_specific_role_other').click
      expect(page).to have_text(I18n.t(:'educator_profile_form.other_please_specify'))
      fill_in(I18n.t(:'educator_profile_form.other_please_specify'), with: 'President')
      click_on('Continue')
      expect(page.current_path).to eq(signup_done_path)
      click_on('Finish')
      wait_for_ajax
      expect(page.current_url).to eq(external_app_url)
    end
  end

  context 'when educator stops signup flow, logs out, after completing step 3' do
    it 'redirects them to continue signup flow (step 4) after logging in'
  end

    let!(:educator) { create_user(email_value, password) }
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

      it 'shows a school name field'

      it 'shows a school-issued email field'
    end
  end

  context 'when educators have been rejected by SheerID one or more times' do
    context 'and have been in the pending faculty status step for more than 4 days' do
      it 'will send them through the CS verification process (modified step 4)'
    end
  end
