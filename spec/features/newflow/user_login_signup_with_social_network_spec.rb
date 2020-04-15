require 'rails_helper'

feature 'User logs in or signs up with a social network', js: true do
  before do
    turn_on_student_feature_flag
    load('db/seeds.rb')
  end

  let(:email) { 'user@example.com' }

  context 'when user signs up with a social network' do
    scenario 'happy path' do
      visit(newflow_login_path)

      simulate_login_signup_with_social(name: 'Elon Musk', email: email) do
        click_on('Facebook')
        wait_for_ajax
        screenshot!
        expect(page).to have_content(t(:"login_signup_form.confirm_your_info"))
        expect(page).to have_field('signup_first_name', with: 'Elon')
        expect(page).to have_field('signup_last_name', with: 'Musk')
        expect(page).to have_field('signup_email', with: email)
        check('signup_terms_accepted')
        wait_for_animations
        screenshot!
        find('[type=submit]').click
        screenshot!
        expect(page).to have_content(t(:"login_signup_form.youre_done", first_name: 'Elon'))
        expect(page).to(
          have_content(strip_html(t(:"login_signup_form.youre_done_description", email_address: email)))
        )
      end
    end

    context 'user denies us access to their email address, has to enter it manually' do
      describe 'success' do
        example do
          visit(newflow_login_path)

          simulate_login_signup_with_social(name: 'Elon Musk', email: nil) do
            click_on('Facebook')
            wait_for_ajax
            wait_for_animations
            screenshot!
            expect(page).to have_content(t(:"login_signup_form.confirm_your_info"))
            expect(page).to have_field('signup_first_name', with: 'Elon')
            expect(page).to have_field('signup_last_name', with: 'Musk')
            expect(page).to have_field('signup_email', with: '')
            submit_signup_form
            screenshot!

            expect(page).to have_content(t(:"login_signup_form.confirm_your_info"))
            expect(page).to have_content(t(:"login_signup_form.email_is_blank"))

            fill_in('signup_email',	with: email)
            submit_signup_form
            screenshot!
            expect(page).to have_content(t(:"login_signup_form.youre_done", first_name: 'Elon'))
            expect(page).to(
              have_content(strip_html(t(:"login_signup_form.youre_done_description", email_address: email)))
            )
          end
        end
      end

      describe 'enters invalid email' do
        subject(:invalid_email) { 'someinvalidemail' }

        scenario 'the form shows a friendly error message' do
          visit(newflow_login_path)

          simulate_login_signup_with_social(name: 'Elon Musk', email: nil) do
            click_on('Facebook')
            wait_for_ajax
            wait_for_animations
            screenshot!
            expect(page).to have_content(t(:"login_signup_form.confirm_your_info"))
            expect(page).to have_field('signup_first_name', with: 'Elon')
            expect(page).to have_field('signup_last_name', with: 'Musk')
            expect(page).to have_field('signup_email', with: '')
            submit_signup_form
            screenshot!

            expect(page).to have_content(t(:"login_signup_form.confirm_your_info"))
            expect(page).to have_content(t(:"login_signup_form.email_is_blank"))

            fill_in('signup_email',	with: invalid_email)
            submit_signup_form
            screenshot!
            expect(page).to have_content(t(:".activerecord.errors.models.email_address.attributes.value.invalid", value: invalid_email))
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
            visit(newflow_login_path)
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
            visit(newflow_login_path)
            click_on('Facebook')
            wait_for_ajax
            screenshot!
            expect(page.current_path).to match(profile_newflow_path)
          end
        end
      end
    end
  end
end
