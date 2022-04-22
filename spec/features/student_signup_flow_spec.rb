require 'rails_helper'
require 'vcr_helper'
require 'byebug'
module Newflow
  feature 'Student signup flow', js: true, vcr: VCR_OPTS do
     before do
      load 'db/seeds.rb'
    end

    before(:all) do
      VCR.use_cassette('Newflow/Students/student_signup_flow/sf_setup', VCR_OPTS) do
        @proxy = SalesforceProxy.new
        @proxy.setup_cassette
      end
    end

    let(:email) do
      Faker::Internet::free_email
    end

    let(:password) do
      Faker::Internet.password(min_length: 8)
    end

    context 'signup happy path' do
      before do
        visit newflow_signup_path(r: '/external_app_for_specs')
        find('.join-as__role.student').click
        fill_in 'signup_first_name',	with: 'Bryan'
        fill_in 'signup_last_name',	with: 'Dimas'
        fill_in 'signup_email',	with: email
        fill_in 'signup_password',	with: password
        check('signup_terms_accepted')
        submit_signup_form
        screenshot!

        # sends an email address confirmation email
        expect(page.current_path).to eq student_email_verification_form_path
        open_email email
        capture_email!(address: email)
        expect(current_email).to be_truthy
      end

      example 'verify email by clicking link in the email' do
        # ... with a link
        verify_email_url = get_path_from_absolute_link(current_email, 'a')
        visit verify_email_url
        # ... which sends you to "sign up done page"
        expect(page).to have_text(t(:'login_signup_form.youre_done', first_name: 'Bryan'))
        screenshot!

        # can exit and go back to the app they came from
        find('#exit-icon a').click
        expect(page.current_path).to eq('/external_app_for_specs')
        screenshot!
      end

      example 'verify email by entering PIN sent in the email' do
        # ... with a link
        pin = current_email.find('b').text
        fill_in('confirm_pin', with: pin)
        screenshot!
        click_on('commit')
        # ... which sends you to "sign up done page"
        expect(page).to have_text(t(:'login_signup_form.youre_done', first_name: 'Bryan'))
        expect(page).to have_text(
          strip_html(t(:'login_signup_form.youre_done_description', email_address: email))
        )
        screenshot!

        # can exit and go back to the app they came from
        find('#exit-icon a').click
        expect(page.current_path).to eq('/external_app_for_specs')
        screenshot!
      end
    end

    context 'when student has not verified their only email address' do
      let!(:user) { FactoryBot.create(:user, state: User::UNVERIFIED, role: User::STUDENT_ROLE) }
      let!(:email_address) { FactoryBot.create(:email_address, user: user, verified: false) }
      let!(:identity) { FactoryBot.create(:identity, user: user, password: password) }
      let!(:password) { 'password' }

      it 'allows the student to log in and redirects them to the email verification form' do
        visit(login_path)
        fill_in('login_form_email', with: email_address.value)
        fill_in('login_form_password', with: password)
        find('[type=submit]').click
        expect(page.current_path).to match(student_email_verification_form_path)
      end

      # TODO: this works - something with the selector, also the id on the element is misspelled
      xit 'allows the student to reset their password' do
        visit(login_path)
        #byebug
        log_in_user(email_address.value, 'WRONGpassword')
        click_link_or_button(t :'login_signup_form.forgot_password')
        expect(page.current_path).to eq(forgot_password_form_path)
        expect(find('#forgot_password_form_email')['value']).to eq(email_address.value)
        screenshot!
        click_link_or_button(t :'login_signup_form.forgot_password')
        screenshot!
      end
    end

  example 'arriving from Tutor (a Doorkeeper app)' do
      app = create_tutor_application
      visit_authorize_uri(app: app, params: { go: 'student_signup' })
      fill_in 'signup_first_name',	with: 'Bryan'
      fill_in 'signup_last_name',	with: 'Dimas'
      fill_in 'signup_email',	with: email
      fill_in 'signup_password',	with: password
      submit_signup_form
      screenshot!

      # sends an email address confirmation email
      expect(page.current_path).to eq student_email_verification_form_path
      open_email email
      capture_email!(address: email)
      expect(current_email).to be_truthy

        # ... with a link
        pin = current_email.find('b').text
        fill_in('confirm_pin', with: pin)
        screenshot!
        click_on('commit')

        # ... redirects you back to Tutor
        expect(page).not_to have_text(t(:'login_signup_form.youre_done', first_name: 'Bryan'))
        expect(page.current_path).to eq('/external_app_for_specs')
    end

    context 'not happy path' do
      example 'user gets PIN wrong' do
        visit newflow_signup_path(r: '/external_app_for_specs')
        find('.join-as__role.student').click
        fill_in 'signup_first_name',	with: 'Bryan'
        fill_in 'signup_last_name',	with: 'Dimas'
        fill_in 'signup_email',	with: email
        fill_in 'signup_password',	with: password
        submit_signup_form
        screenshot!

        # TARGET
        fill_in('confirm_pin', with: '123456') # wrong pin
        click_on('commit')
        screenshot!
        expect(page).to have_text(t(:'login_signup_form.pin_not_correct'))
      end
    end

    context 'change signup email' do
      example 'user can change their initial email during the signup flow' do
        visit newflow_signup_path(r: '/external_app_for_specs')
        find('.join-as__role.student').click
        fill_in 'signup_first_name',	with: 'Bryan'
        fill_in 'signup_last_name',	with: 'Dimas'
        fill_in 'signup_email',	with: email
        fill_in 'signup_password',	with: password
        submit_signup_form
        screenshot!

        # an email gets sent
        open_email email
        # capture_email!(address: email)
        expect(current_email).to be_truthy
        old_pin = current_email.find('b').text
        old_confirmation_code_url = get_path_from_absolute_link(current_email, 'a')

        # edit email
        click_on('edit your email')
        screenshot!
        # page contains tooltip
        expect(page).to have_text(t(:'login_signup_form.change_signup_email_form_tooltip'))

        new_email = Faker::Internet::free_email
        fill_in('change_signup_email_email', with: new_email)
        screenshot!
        find('#login-signup-form').click
        wait_for_animations
        click_on('commit')
        screenshot!
        expect(page).to have_text(t(:'login_signup_form.check_your_updated_email'))

        # a different pin is sent in the edited email
        open_email new_email
        capture_email!(address: new_email)
        pin = current_email.find('b').text
        expect(pin).not_to eq(old_pin)
        # ...as well as a different confirmation code url
        confirmation_code_url = get_path_from_absolute_link(current_email, 'a')
        expect(confirmation_code_url).not_to eq(old_confirmation_code_url)

        screenshot!
        expect(page.current_path).to eq(student_email_verification_form_updated_email_path)
      end
    end

    def create_tutor_application
      app = FactoryBot.create(:doorkeeper_application, skip_terms: true,
                          can_access_private_user_data: true,
                          can_skip_oauth_screen: true, name: 'Tutor')

    # We want to provide a local "external" redirect uri so our specs aren't actually
    # making HTTP calls against real external URLs like "example.com"
    server = Capybara.current_session.try(:server)
    redirect_uri = "http://#{server.host}:#{server.port}#{external_app_for_specs_path}"
    app.update_columns(:redirect_uri => redirect_uri)

    FactoryBot.create(:doorkeeper_access_token, application: app, resource_owner_id: nil)
    app
    end
  end
end
