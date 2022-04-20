require 'rails_helper'

feature 'User logs in or signs up with a social network', js: true do
  before do
    load('db/seeds.rb')
    allow_any_instance_of(CreateSalesforceLead).to receive(:exec)
  end

  let(:email) { 'user@example.com' }

  context 'students' do
    context 'when user signs up with a social network' do
      scenario 'happy path' do
        visit(signup_student_path)

        simulate_login_signup_with_social(name: 'Elon Musk', email: email) do
          click_on('Facebook')
          wait_for_ajax
          screenshot!
          expect(page).to have_content(t(:'login_signup_form.confirm_your_info'))
          expect(page).to have_field('signup_first_name', with: 'Elon')
          expect(page).to have_field('signup_last_name', with: 'Musk')
          expect(page).to have_field('signup_email', with: email)
          check('signup_terms_accepted')
          wait_for_animations
          screenshot!
          submit_signup_form
          screenshot!
          expect(page).to have_content(t(:'login_signup_form.youre_done', first_name: 'Elon'))
          expect(page).to(
            have_content(strip_html(t(:'login_signup_form.youre_done_description', email_address: email)))
          )
        end
      end

      context 'user denies us access to their email address, has to enter it manually' do
        describe 'success' do
          example do
            visit(signup_student_path)

            simulate_login_signup_with_social(name: 'Elon Musk', email: nil) do
              click_on('Facebook')
              wait_for_ajax
              wait_for_animations
              screenshot!
              expect(page).to have_content(t(:'login_signup_form.confirm_your_info'))
              expect(page).to have_field('signup_first_name', with: 'Elon')
              expect(page).to have_field('signup_last_name', with: 'Musk')
              expect(page).to have_field('signup_email', with: '')
              submit_signup_form
              screenshot!

              expect(page).to have_content(t(:'login_signup_form.confirm_your_info'))
              expect(page).to have_content(t(:'login_signup_form.email_is_blank'))

              fill_in('signup_email',	with: email)
              submit_signup_form
              screenshot!
              expect(page).to have_content(t(:'login_signup_form.youre_done', first_name: 'Elon'))
              expect(page).to(
                have_content(strip_html(t(:'login_signup_form.youre_done_description', email_address: email)))
              )
            end
          end
        end

        describe 'enters invalid email' do
          subject(:invalid_email) { 'someinvalidemail' }

          scenario 'the form shows a friendly error message' do
            visit(signup_student_path)

            simulate_login_signup_with_social(name: 'Elon Musk', email: nil) do
              click_on('Facebook')
              wait_for_ajax
              wait_for_animations
              screenshot!
              expect(page).to have_content(t(:'login_signup_form.confirm_your_info'))
              expect(page).to have_field('signup_first_name', with: 'Elon')
              expect(page).to have_field('signup_last_name', with: 'Musk')
              expect(page).to have_field('signup_email', with: '')
              submit_signup_form
              screenshot!

              expect(page).to have_content(t(:'login_signup_form.confirm_your_info'))
              expect(page).to have_content(t(:'login_signup_form.email_is_blank'))

              fill_in('signup_email',	with: invalid_email)
              submit_signup_form
              screenshot!
              expect(page).to have_content(t(:'.activerecord.errors.models.email_address.attributes.value.invalid', value: invalid_email))
            end
          end
        end
      end
    end

    context 'when user logs in with a social network' do
      let(:user) do
        FactoryBot.create(:user, :terms_agreed)
      end

      let(:email) do
        Faker::Internet.free_email
      end

      before do
        FactoryBot.create(:authentication, provider: :facebooknewflow, user: user, uid: 'uid123')
        FactoryBot.create(:email_address, user: user, value: email, verified: true)
      end

      describe 'happy path' do
        scenario 'youre successfully logged in' do
          simulate_login_signup_with_social(name: 'Elon Musk', email: email, uid: 'uid123') do
              visit(login_path)
              click_on('Facebook')
              wait_for_ajax
              screenshot!
              expect(page.current_path).to match(profile_newflow_path)
            end
        end
      end

      context 'when user removes OpenStax from the list of Facebook apps' do
        describe 'rejects access to their email address' do
          scenario 'youre successfully logged in' do
            simulate_login_signup_with_social(name: 'Elon Musk', email: nil, uid: 'uid123') do
              visit(login_path)
              click_on('Facebook')
              wait_for_ajax
              screenshot!
              expect(page.current_path).to match(profile_newflow_path)
            end
          end
        end
      end
    end

    context 'when user denies us access to their email address, signs up entering their email manually' do
      let(:email_value) { Faker::Internet.free_email }
      let(:nil_email_value) { nil }

      before do
        visit(signup_student_path)

        simulate_login_signup_with_social(name: 'Elon Musk', email: nil_email_value) do
          click_on('Facebook')
          wait_for_ajax
          wait_for_animations
          screenshot!

          fill_in('signup_email',	with: email_value)
          submit_signup_form
          screenshot!

          expect(page).to(
            have_content(strip_html(t(:'login_signup_form.youre_done_description', email_address: email_value)))
          )
          click_on('Finish')
          click_on('Log out')
        end
      end

      scenario 'user can subsequently log in' do
        simulate_login_signup_with_social(name: 'Elon Musk', email: nil_email_value) do
          click_on('Facebook')
          expect(page.current_path).to match(profile_newflow_path)
          expect(page).to have_content(email_value)
        end
      end
    end

    context 'when user already had a facebook login in the old flow' do
      let(:user) do
        FactoryBot.create(:user, :terms_agreed)
      end

      let(:email_value) do
        Faker::Internet.free_email
      end

      let(:social_uid) { 'uid123' }

      before do
        FactoryBot.create(:authentication, provider: :facebook, user: user, uid: social_uid)
        FactoryBot.create(:email_address, user: user, value: email_value, verified: true)
      end

      context 'tries to log in in the newflow' do
        describe 'denies us access to their email address' do
          let(:nil_email_value) { nil }

          scenario 'is successfully logged in' do
            simulate_login_signup_with_social(email: nil_email_value, uid: social_uid) do
              visit(login_path)
              click_on('Facebook')
              wait_for_ajax
              screenshot!
              expect(page.current_path).to match(profile_newflow_path)

              # A `facebooknewflow` auth was created since the user already had a `facebook` one
              expect(user.authentications.count).to eq(2)
            end
          end
        end

        describe 'gives us access to their email address' do
          let(:email_address) { email_value }

          scenario 'is successfully logged in' do
            simulate_login_signup_with_social(email: email_address, uid: social_uid) do
              visit(login_path)
              click_on('Facebook')
              wait_for_ajax
              screenshot!
              expect(page.current_path).to match(profile_newflow_path)
              expect(page).to have_content(email_value)
            end
          end
        end
      end
    end
  end

  context 'when user wants to log in with a social network but there is no account found' do
    scenario 'the log in page re-renders with a blue banner and a message "[...] trying to sign up?"' do
      visit(login_path)

      simulate_login_signup_with_social(name: 'Elon Musk', email: email) do
        click_on('Google')
        wait_for_ajax
        expect(page).to have_content(
          t(
            :'login_signup_form.should_social_signup',
            sign_up: t(:'login_signup_form.sign_up')
          )
        )
        screenshot!
      end
    end
  end
end
