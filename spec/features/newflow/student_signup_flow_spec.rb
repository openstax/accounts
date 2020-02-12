require 'rails_helper'

module Newflow
  feature 'Student signup flow', js: true do
     before do
      load 'db/seeds.rb'
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
        check 'signup_terms_accepted'
        screenshot!
        find('#signup_form_submit_button').click
        screenshot!

        # sends an email address confirmation email
        expect(page.current_path).to eq confirmation_form_path
        open_email email
        capture_email!(address: email)
        expect(current_email).to be_truthy
      end

      example 'verify email by clicking link in the email' do
        # ... with a link
        verify_email_url = get_path_from_absolute_link(current_email, 'a')
        visit verify_email_url
        # ... which sends you to "sign up done page"
        expect(page).to have_text(t(:"login_signup_form.youre_done", first_name: 'Bryan'))
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
        expect(page).to have_text(t(:"login_signup_form.youre_done", first_name: 'Bryan'))
        expect(page).to have_text(
          strip_html(t(:"login_signup_form.youre_done_description", email_address: email))
        )
        screenshot!

        # can exit and go back to the app they came from
        find('#exit-icon a').click
        expect(page.current_path).to eq('/external_app_for_specs')
        screenshot!
      end
    end

    context 'not happy path' do
      example 'user gets PIN wrong' do
        visit newflow_signup_path(r: '/external_app_for_specs')
        find('.join-as__role.student').click
        fill_in 'signup_first_name',	with: 'Bryan'
        fill_in 'signup_last_name',	with: 'Dimas'
        fill_in 'signup_email',	with: email
        fill_in 'signup_password',	with: password
        check 'signup_terms_accepted'
        screenshot!
        find('#signup_form_submit_button').click
        screenshot!

        # TARGET
        fill_in('confirm_pin', with: '123456') # wrong pin
        click_on('commit')
        screenshot!
        expect(page).to have_text(t(:"login_signup_form.pin_not_correct"))
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
        check 'signup_terms_accepted'
        screenshot!
        find('#signup_form_submit_button').click
        screenshot!

        # an email gets sent
        open_email email
        # capture_email!(address: email)
        expect(current_email).to be_truthy
        old_pin = current_email.find('b').text
        old_pin = EmailAddress.last.confirmation_pin
        old_confirmation_code_url = get_path_from_absolute_link(current_email, 'a')

        # edit email
        click_on('edit your email')
        screenshot!
        # page contains tooltip
        expect(page).to have_text(t('login_signup_form.change_your_email_tooltip'))

        new_email = Faker::Internet::free_email
        fill_in('change_signup_email_email', with: new_email)
        screenshot!
        click_on('commit')
        screenshot!
        expect(page).to have_text(t('login_signup_form.check_your_updated_email'))

        # a different pin is sent in the edited email
        open_email new_email
        capture_email!(address: new_email)
        pin = current_email.find('b').text
        expect(pin).not_to eq(old_pin)
        # ...as well as a different confirmation code url (which invalidates the old one -- right? bryan)
        confirmation_code_url = get_path_from_absolute_link(current_email, 'a')
        expect(confirmation_code_url).not_to eq(old_confirmation_code_url)

        # finally finish signup
        fill_in('confirm_pin', with: pin)
        screenshot!
        click_on('commit')
        # ... which sends you to "sign up done page"
        screenshot!
        expect(page).to have_text(t(:"login_signup_form.youre_done", first_name: 'Bryan'))
        expect(page).to(
          have_text(
            strip_html(
              t(:"login_signup_form.youre_done_description", email_address: new_email)
            )
          )
        )

        # can exit and go back to the app they came from
        find('#exit-icon a').click
        expect(page.current_path).to eq('/external_app_for_specs')
        screenshot!
      end
    end

    context 'happy path with signed params and feature flag ON' do
      before do
        turn_on_feature_flag
      end

      background do
        load 'db/seeds.rb'
        create_default_application
      end

      let(:role) do
        'student'
      end

      let(:payload) do
        {
          role:  role,
          uuid: SecureRandom.uuid,
          name:  'Tester McTesterson',
          email: 'test@example.com',
          school: 'Testing U'
        }
      end

      let(:signed_params) do
        { sp: OpenStax::Api::Params.sign(params: payload, secret: @app.secret) }
      end

      example 'uses the signed parameters' do
        arrive_from_app(params: signed_params, do_expect: false)

        expect(page).to have_field('signup_first_name', with: 'Tester')
        expect(page).to have_field('signup_last_name', with: 'McTesterson')
        expect(page).to have_field('signup_email', with: payload[:email])
        # skip password since it's trusted # fill_in 'signup_password',	with: 'password'
        check 'signup_newsletter'
        check 'signup_terms_accepted'
        screenshot!
        find('#signup_form_submit_button').click
        screenshot!

        expect(User.last.external_uuids.where(uuid: payload[:uuid]).exists?).to be(true)
        expect(User.last.self_reported_school).to eq(payload[:school])

        email = EmailAddress.find_by!(value: payload[:email])
        fill_in('confirm_pin', with: email.confirmation_pin)

        find('[type=submit]').click

        find('[type=submit]').click

        expect_back_at_app

        expect_validated_records(params: payload)
      end
    end

    def expect_validated_records(params:, user: User.last, email_is_verified: true)
      expect(user.external_uuids.where(uuid: params[:uuid]).exists?).to be(true)
      expect(user.email_addresses.count).to eq(1)
      email = user.email_addresses.first
      expect(email.verified).to be(email_is_verified)
    end
  end
end
