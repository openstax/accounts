require 'rails_helper'
require 'rake'

describe 'accounts:repair_faculty_status_from_sheerid' do
  include_context 'rake'

  # Keyed by verification_id, not object identity: the task loads its own
  # fresh AR instances.
  let(:computed_statuses) { {} }

  before do
    stub_sentry
    allow_any_instance_of(SheeridVerification).to(
      receive(:faculty_status_for_step) { |instance| computed_statuses.fetch(instance.verification_id) }
    )
  end

  def link_verification(user, status)
    verification = FactoryBot.create(:sheerid_verification, verification_id: SecureRandom.uuid)
    computed_statuses[verification.verification_id] = status
    user.update!(sheerid_verification_id: verification.verification_id)
    verification
  end

  it "advances a user's faculty_status to match their verification and logs the repair" do
    user = FactoryBot.create :user, faculty_status: :pending_sheerid
    link_verification(user, User::CONFIRMED_FACULTY)

    expect(Newflow::CreateOrUpdateSalesforceLead).to receive(:perform_later).with(user: user)

    subject.invoke

    expect(user.reload.faculty_status).to eq('confirmed_faculty')
    log = SecurityLog.find_by(event_type: 'faculty_status_repaired', user: user)
    expect(log.event_data['from']).to eq('pending_sheerid')
    expect(log.event_data['to']).to eq('confirmed_faculty')
  end

  it 'refuses a downgrade (the ladder logs the refusal; no repair log, no lead push)' do
    user = FactoryBot.create :user, faculty_status: :confirmed_faculty
    link_verification(user, User::REJECTED_BY_SHEERID)

    expect(Newflow::CreateOrUpdateSalesforceLead).not_to receive(:perform_later)

    subject.invoke

    expect(user.reload.faculty_status).to eq('confirmed_faculty')
    expect(SecurityLog.where(event_type: 'faculty_status_repaired', user: user)).to be_empty
    expect(SecurityLog.where(event_type: 'faculty_status_downgrade_refused', user: user)).not_to be_empty
  end

  it 'is a no-op when the computed status already matches (idempotent)' do
    user = FactoryBot.create :user, faculty_status: :confirmed_faculty
    link_verification(user, User::CONFIRMED_FACULTY)

    expect(Newflow::CreateOrUpdateSalesforceLead).not_to receive(:perform_later)

    subject.invoke

    expect(SecurityLog.where(event_type: 'faculty_status_repaired', user: user)).to be_empty
  end

  it 'skips users with no linked SheeridVerification row' do
    user = FactoryBot.create :user, faculty_status: :pending_sheerid, sheerid_verification_id: 'orphaned-id'

    expect { subject.invoke }.not_to raise_error

    expect(user.reload.faculty_status).to eq('pending_sheerid')
  end

  it 'ignores users with no sheerid_verification_id at all' do
    user = FactoryBot.create :user, faculty_status: :no_faculty_info, sheerid_verification_id: nil

    subject.invoke

    expect(user.reload.faculty_status).to eq('no_faculty_info')
  end

  describe 'DRY_RUN' do
    it 'writes nothing but reports the transition it would make' do
      user = FactoryBot.create :user, faculty_status: :pending_sheerid
      link_verification(user, User::CONFIRMED_FACULTY)
      stub_const('ENV', ENV.to_hash.merge('DRY_RUN' => 'true'))

      expect(Newflow::CreateOrUpdateSalesforceLead).not_to receive(:perform_later)

      subject.invoke

      expect(user.reload.faculty_status).to eq('pending_sheerid')
      expect(SecurityLog.where(event_type: 'faculty_status_repaired', user: user)).to be_empty
    end
  end
end
