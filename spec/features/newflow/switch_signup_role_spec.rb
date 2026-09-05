require 'rails_helper'

# The handler and controller specs call `switch_role` directly. These two exercise
# the links themselves, which are `button_to`s rendered inside the signup card --
# the combination that has silently broken here before (a `button_to` nested in a
# form is dropped by the browser, and `#login-signup-form` styles submits at ID
# specificity). A spec that never renders the page would not notice.
module Newflow
  feature 'Switching signup role from the signup pages', js: true do
    let(:password) { 'password' }
    let(:email) { Faker::Internet.email }

    context 'a student on the done page' do
      # The user factory defaults is_profile_complete to true, which only
      # EducatorSignup::CompleteProfile ever sets in production. Left true it makes
      # step_3_complete? true, and the switch lands on /i/profile instead of SheerID.
      let!(:student) do
        create_newflow_user(email, password, nil, nil, 'student')
          .tap { |user| user.update!(is_profile_complete: false) }
      end

      before do
        visit newflow_login_path
        complete_newflow_log_in_screen(email, password)
        wait_for_successful_log_in
        visit signup_done_path
      end

      it 'switches to educator and lands on the SheerID step' do
        click_on(I18n.t(:"login_signup_form.switch_role_educator"))

        expect(page).to have_current_path(educator_sheerid_form_path)
        expect(student.reload.role).to eq('instructor')
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
