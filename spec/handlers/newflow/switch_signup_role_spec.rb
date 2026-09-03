require 'rails_helper'

module Newflow
  describe SwitchSignupRole, type: :handler do

    context 'educator switching to student' do
      let(:user) do
        FactoryBot.create(
          :user,
          role: User::INSTRUCTOR_ROLE,
          faculty_status: User::PENDING_FACULTY,
          sheerid_verification_id: 'SHEERID_123',
          sheerid_reported_school: 'Wayne State University',
          is_sheerid_unviable: true,
          is_educator_pending_cs_verification: true,
          requested_cs_verification_at: DateTime.now,
          is_profile_complete: true
        )
      end

      it 'makes them a student and clears every educator flag' do
        result = described_class.call(user: user)

        expect(result.errors).to be_empty
        expect(result.outputs.switched_to).to eq(:student)

        user.reload
        expect(user.role).to eq('student')
        expect(user.faculty_status).to eq(User::NO_FACULTY_INFO)
        expect(user.sheerid_verification_id).to be_nil
        expect(user.sheerid_reported_school).to be_nil
        expect(user.is_sheerid_unviable).to eq(false)
        expect(user.is_educator_pending_cs_verification).to eq(false)
        expect(user.requested_cs_verification_at).to be_nil
        expect(user.is_profile_complete).to eq(false)
      end

      it 'updates the salesforce lead so it reflects the new role' do
        expect(UpdateExistingSalesforceLead).to receive(:perform_later).with(user: user)

        described_class.call(user: user)
      end

      it 'logs the switch' do
        described_class.call(user: user)

        log = SecurityLog.find_by(event_type: :user_switched_signup_role)
        expect(log.user_id).to eq(user.id)
        expect(log.event_data['role_was']).to eq('instructor')
        expect(log.event_data['role_now']).to eq('student')
      end
    end

    context 'student switching to educator' do
      let(:user) { FactoryBot.create(:user, role: User::STUDENT_ROLE) }

      it 'makes them an instructor with an incomplete signup' do
        allow(UpdateExistingSalesforceLead).to receive(:perform_later)

        result = described_class.call(user: user)

        expect(result.errors).to be_empty
        expect(result.outputs.switched_to).to eq(:educator)
        expect(user.reload.role).to eq('instructor')
        expect(user.faculty_status).to eq(User::INCOMPLETE_SIGNUP)
        expect(UpdateExistingSalesforceLead).not_to have_received(:perform_later)
      end
    end

    it 'refuses to undo a confirmed faculty verification' do
      user = FactoryBot.create(
        :user, role: User::INSTRUCTOR_ROLE, faculty_status: User::CONFIRMED_FACULTY
      )

      result = described_class.call(user: user)

      expect(result.errors.map(&:code)).to eq([:already_verified_faculty])
      expect(user.reload.role).to eq('instructor')
    end

    it 'errors when there is no signup in progress' do
      result = described_class.call(user: nil)

      expect(result.errors.map(&:code)).to eq([:no_signup_in_progress])
    end
  end
end
