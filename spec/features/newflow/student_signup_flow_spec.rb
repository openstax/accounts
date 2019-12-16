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
        visit newflow_signup_path
        find('.join-as__role.student').click
        fill_in 'signup_first_name',	with: 'Bryan'
        fill_in 'signup_last_name',	with: 'Dimas'
        fill_in 'signup_email',	with: email
        fill_in 'signup_password',	with: password
        check 'signup_terms_accepted'
        find('#signup_form_submit_button').click

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
      end

      example 'verify email by entering PIN sent in the email' do
        # ... with a link
        pin = current_email.find('b').text
        fill_in('confirm_pin', with: pin)
        click_on('commit')
        # ... which sends you to "sign up done page"
        expect(page).to have_text(t(:"login_signup_form.youre_done", first_name: 'Bryan'))
        expect(page).to have_text(
          strip_html(t(:"login_signup_form.youre_done_description", email_address: email))
        )
      end
    end

    context 'change signup email' do
      example 'user can change their initial email during the signup flow' do
        visit newflow_signup_path
        find('.join-as__role.student').click
        fill_in 'signup_first_name',	with: 'Bryan'
        fill_in 'signup_last_name',	with: 'Dimas'
        fill_in 'signup_email',	with: email
        fill_in 'signup_password',	with: password
        check 'signup_terms_accepted'
        find('#signup_form_submit_button').click
        # an email gets sent
        open_email email
        # capture_email!(address: email)
        expect(current_email).to be_truthy
        old_pin = current_email.find('b').text
        old_pin = EmailAddress.last.confirmation_pin
        old_confirmation_code_url = get_path_from_absolute_link(current_email, 'a')

        # edit email
        click_on('edit your email')

        # page contains tooltip
        expect(page).to have_text(t('login_signup_form.change_your_email_tooltip'))

        new_email = Faker::Internet::free_email
        fill_in('change_signup_email_email', with: new_email)
        click_on('commit')
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
        click_on('commit')
        # ... which sends you to "sign up done page"
        expect(page).to have_text(t(:"login_signup_form.youre_done", first_name: 'Bryan'))
        expect(page).to(
          have_text(
            strip_html(
              t(:"login_signup_form.youre_done_description", email_address: new_email)
            )
          )
        )
      end
    end
  end
end
