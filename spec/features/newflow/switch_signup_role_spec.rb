require 'rails_helper'

# The handler and controller specs call `switch_role` directly. These exercise
# the links themselves, which are `button_to`s rendered inside the signup card --
# the combination that has silently broken here before (a `button_to` nested in a
# form is dropped by the browser, and `#login-signup-form` styles submits at ID
# specificity). A spec that never renders the page would not notice. They also pin
# down where the switch is offered at all: never on the PIN screen, and on the done
# page only to social signups.
module Newflow
  feature 'Switching signup role from the signup pages', js: true do
    let(:password) { 'password' }
    let(:email) { Faker::Internet.email }

    context 'an unverified student on the email confirmation step' do
      before do
        create_newflow_user(email, password, nil, '123456', 'student')
          .update!(state: User::UNVERIFIED)
        visit newflow_login_path
        complete_newflow_log_in_screen(email, password)
        expect(page).to have_current_path(student_email_verification_form_path)
      end

      it 'does not offer a role switch' do
        expect(page).to have_field('confirm_pin')
        expect(page).to have_no_css('.signup-alternatives')
        expect(page).to have_no_button(I18n.t(:"login_signup_form.switch_role_educator"))
      end
    end

    context 'an unverified educator on the email confirmation step' do
      before do
        create_newflow_user(email, password, nil, '123456', 'instructor')
          .update!(state: User::UNVERIFIED)
        visit newflow_login_path
        complete_newflow_log_in_screen(email, password)
        expect(page).to have_current_path(educator_email_verification_form_path)
      end

      it 'does not offer a role switch' do
        expect(page).to have_field('confirm_pin')
        expect(page).to have_no_css('.signup-alternatives')
        expect(page).to have_no_button(I18n.t(:"login_signup_form.switch_role_student"))
      end
    end

    context 'a student who signed up with a password, on the done page' do
      let!(:student) { create_newflow_user(email, password, nil, nil, 'student') }

      before do
        visit newflow_login_path
        complete_newflow_log_in_screen(email, password)
        wait_for_successful_log_in
        visit signup_done_path
      end

      # They picked "student" on the welcome page, which offers both roles.
      it 'does not offer a role switch' do
        expect(page).to have_text(
          I18n.t(:"login_signup_form.youre_done", first_name: student.first_name)
        )
        expect(page).to have_no_css('.signup-alternatives')
      end
    end

    context 'a student who signed up with a social network, on the done page' do
      before do
        turn_on_student_feature_flag
        turn_on_educator_feature_flag
        visit(newflow_signup_student_path)

        simulate_login_signup_with_social(name: 'Elon Musk', email: email) do
          click_on('Facebook')
          wait_for_ajax
          expect(page).to have_field('signup_email', with: email)
          check('signup_terms_accepted')
          submit_signup_form
          expect(page).to have_text(I18n.t(:"login_signup_form.youre_done", first_name: 'Elon'))
        end
      end

      # Social signup only ever creates students, so this is an instructor's
      # only way into the educator funnel from there.
      it 'switches to educator and lands on the SheerID step' do
        expect(page).to have_text(I18n.t(:"login_signup_form.alternatives_heading_educator"))
        click_on(I18n.t(:"login_signup_form.switch_role_educator"))

        expect(page).to have_current_path(educator_sheerid_form_path)
        expect(page).to have_text(I18n.t(:"login_signup_form.switched_role_notice.educator"))
        expect(EmailAddress.find_by!(value: email).user.role).to eq('instructor')
      end
    end

    context 'an educator on the SheerID step' do
      let!(:educator) do
        create_newflow_user(email, password, nil, nil, 'instructor')
          .tap do |user|
            user.update!(faculty_status: User::INCOMPLETE_SIGNUP, is_profile_complete: false)
          end
      end

      before do
        visit newflow_login_path
        complete_newflow_log_in_screen(email, password)
        wait_for_successful_log_in
        visit educator_sheerid_form_path
      end

      # Visible from the start, so it has to stay out of the page's autofocus or a
      # stray Enter would switch the account.
      it 'offers the switch without a click to reveal it, and not under focus' do
        expect(page).to have_button(I18n.t(:"login_signup_form.switch_role_student"))
        expect(page).to have_link(I18n.t(:"login_signup_form.alternative_manual_verification"))
        focused = page.evaluate_script('document.activeElement.className')
        expect(focused).not_to include('signup-alternatives')
      end

      it 'switches to student and is not offered the way back on the done page' do
        click_on(I18n.t(:"login_signup_form.switch_role_student"))

        expect(page).to have_current_path(signup_done_path)
        expect(page).to have_text(I18n.t(:"login_signup_form.switched_role_notice.student"))
        expect(page).to have_no_css('.signup-alternatives')
        expect(educator.reload.role).to eq('student')
      end
    end

    context 'an educator on the profile step' do
      let!(:educator) do
        user = create_newflow_user(email, password, nil, nil, 'instructor')
        user.update!(
          faculty_status: User::PENDING_FACULTY,
          sheerid_verification_id: 'sheerid-verification-123',
          is_profile_complete: false
        )
        user
      end

      before do
        visit newflow_login_path
        complete_newflow_log_in_screen(email, password)
        wait_for_successful_log_in
        visit educator_profile_form_path
      end

      # The profile form's JS validation used to bind to every form in the card,
      # so the switch was refused until the profile questions were answered.
      it 'switches to student without answering the profile questions' do
        find('.signup-alternatives__summary').click
        click_on(I18n.t(:"login_signup_form.switch_role_student"))

        expect(page).to have_current_path(signup_done_path)
        expect(page).to have_text(I18n.t(:"login_signup_form.switched_role_notice.student"))
        expect(educator.reload.role).to eq('student')
      end
    end

    context 'an educator waiting on CS verification' do
      let!(:educator) do
        user = create_newflow_user(email, password, nil, nil, 'instructor')
        user.update!(
          faculty_status: User::PENDING_FACULTY,
          is_educator_pending_cs_verification: true,
          requested_cs_verification_at: Time.current,
          is_profile_complete: true
        )
        user
      end

      before do
        visit newflow_login_path
        complete_newflow_log_in_screen(email, password)
        wait_for_successful_log_in
        visit educator_pending_cs_verification_path
      end

      it 'switches to student and clears the educator artifacts' do
        # The actions are behind a <details> so they don't outrank the message.
        # `click_on` matches links and buttons; <summary> is neither.
        find('.signup-alternatives__summary').click
        click_on(I18n.t(:"login_signup_form.switch_role_student"))

        expect(page).to have_current_path(signup_done_path)
        expect(page).to have_text(I18n.t(:"login_signup_form.switched_role_notice.student"))

        educator.reload
        expect(educator.role).to eq('student')
        expect(educator.faculty_status).to eq('rejected_faculty')
        expect(educator.is_educator_pending_cs_verification).to eq(false)
        expect(educator.is_profile_complete).to eq(false)
        expect(educator.requested_cs_verification_at).to be_nil
      end
    end
  end
end
