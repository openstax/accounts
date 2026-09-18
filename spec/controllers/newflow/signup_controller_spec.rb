require 'rails_helper'

module Newflow
  describe SignupController, type: :controller do
    describe 'GET #welcome' do
      it 'renders welcome form/page' do
        get(:welcome)
        expect(response).to render_template(:welcome)
      end
    end

    describe 'GET #signup_done' do
      let(:user) { FactoryBot.create(:user) }

      before do
        mock_current_user(user)
        allow(OXPosthog).to receive(:log)
      end

      it 'renders' do
        get(:signup_done)
        expect(response).to render_template(:signup_done)
      end

      it 'captures user_signup_done once per account, not once per render' do
        get(:signup_done)
        get(:signup_done)

        expect(OXPosthog).to have_received(:log).with(
          user, 'user_signup_done', hash_including(role: user.role)
        ).once
        expect(user.reload.signup_done_captured_at).to be_present
      end

      it 'does not capture again for an account that already completed signup' do
        user.update_column(:signup_done_captured_at, 1.week.ago)

        get(:signup_done)

        expect(response).to render_template(:signup_done)
        expect(OXPosthog).not_to have_received(:log).with(
          user, 'user_signup_done', anything
        )
      end
    end
    describe 'POST #switch_role' do
      before { allow(UpdateExistingSalesforceLead).to receive(:perform_later) }

      it 'sends an educator who has not verified their email back to the student PIN screen' do
        user = FactoryBot.create(
          :user, state: User::UNVERIFIED, role: User::INSTRUCTOR_ROLE,
          faculty_status: User::INCOMPLETE_SIGNUP
        )
        session[:unverified_user_id] = user.id

        post(:switch_role)

        expect(response).to redirect_to(student_email_verification_form_path)
        expect(user.reload.role).to eq('student')
      end

      it 'sends a signed-in student into instructor verification' do
        user = FactoryBot.create(:user, role: User::STUDENT_ROLE)
        mock_current_user(user)

        post(:switch_role)

        expect(response).to redirect_to(educator_sheerid_form_path)
        expect(user.reload.role).to eq('instructor')
      end

      it 'sends a signed-in educator to the student done screen' do
        user = FactoryBot.create(
          :user, role: User::INSTRUCTOR_ROLE, faculty_status: User::PENDING_FACULTY
        )
        mock_current_user(user)

        post(:switch_role)

        expect(response).to redirect_to(signup_done_path)
        expect(user.reload.role).to eq('student')
      end

      it 'restarts signup when there is nothing in progress' do
        post(:switch_role)

        expect(response).to redirect_to(newflow_signup_path)
      end
    end
  end
end
