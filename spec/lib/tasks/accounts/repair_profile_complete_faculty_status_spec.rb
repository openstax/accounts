require 'rails_helper'
require 'rake'

describe 'accounts:repair_profile_complete_faculty_status' do
  include_context 'rake'

  before { stub_sentry }

  it "advances a non-student user's faculty_status to pending_faculty and logs the repair" do
    user = FactoryBot.create(
      :user, role: User::INSTRUCTOR_ROLE, faculty_status: :incomplete_signup,
             profile_completed_at: Time.current
    )

    expect(Newflow::CreateOrUpdateSalesforceLead).to receive(:perform_later).with(user: user)

    subject.invoke

    expect(user.reload.faculty_status).to eq('pending_faculty')
    log = SecurityLog.find_by(event_type: 'faculty_status_repaired', user: user)
    expect(log.event_data['from']).to eq('incomplete_signup')
    expect(log.event_data['to']).to eq('pending_faculty')
    expect(log.event_data['reason']).to eq('profile_completed_repair')
  end

  it 'rolls the advance back when the lead push cannot be enqueued, so a rerun still finds the user' do
    user = FactoryBot.create(
      :user, role: User::INSTRUCTOR_ROLE, faculty_status: :incomplete_signup,
             profile_completed_at: Time.current
    )
    allow(Newflow::CreateOrUpdateSalesforceLead).to receive(:perform_later).and_raise(StandardError, 'queue down')

    expect { subject.invoke }.to output(/failed: 1/).to_stdout_from_any_process

    expect(user.reload.faculty_status).to eq('incomplete_signup')
    expect(SecurityLog.where(event_type: 'faculty_status_repaired', user: user)).to be_empty
  end

  it 'skips a user whose profile_completed_at is nil' do
    user = FactoryBot.create(
      :user, role: User::INSTRUCTOR_ROLE, faculty_status: :incomplete_signup,
             profile_completed_at: nil
    )

    expect(Newflow::CreateOrUpdateSalesforceLead).not_to receive(:perform_later)

    subject.invoke

    expect(user.reload.faculty_status).to eq('incomplete_signup')
  end

  it 'skips a student even with profile_completed_at set and incomplete_signup' do
    user = FactoryBot.create(
      :user, role: User::STUDENT_ROLE, faculty_status: :incomplete_signup,
             profile_completed_at: Time.current
    )

    expect(Newflow::CreateOrUpdateSalesforceLead).not_to receive(:perform_later)

    subject.invoke

    expect(user.reload.faculty_status).to eq('incomplete_signup')
  end

  it 'skips a user already at pending_faculty' do
    user = FactoryBot.create(
      :user, role: User::INSTRUCTOR_ROLE, faculty_status: :pending_faculty,
             profile_completed_at: Time.current
    )

    expect(Newflow::CreateOrUpdateSalesforceLead).not_to receive(:perform_later)

    subject.invoke

    expect(user.reload.faculty_status).to eq('pending_faculty')
  end

  it 'skips a user already at confirmed_faculty' do
    user = FactoryBot.create(
      :user, role: User::INSTRUCTOR_ROLE, faculty_status: :confirmed_faculty,
             profile_completed_at: Time.current
    )

    expect(Newflow::CreateOrUpdateSalesforceLead).not_to receive(:perform_later)

    subject.invoke

    expect(user.reload.faculty_status).to eq('confirmed_faculty')
  end

  describe 'DRY_RUN' do
    it 'changes nothing and pushes no leads' do
      user = FactoryBot.create(
        :user, role: User::INSTRUCTOR_ROLE, faculty_status: :incomplete_signup,
               profile_completed_at: Time.current
      )
      stub_const('ENV', ENV.to_hash.merge('DRY_RUN' => 'true'))

      expect(Newflow::CreateOrUpdateSalesforceLead).not_to receive(:perform_later)

      subject.invoke

      expect(user.reload.faculty_status).to eq('incomplete_signup')
      expect(SecurityLog.where(event_type: 'faculty_status_repaired', user: user)).to be_empty
    end
  end
end
