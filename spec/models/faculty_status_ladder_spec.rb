require 'rails_helper'

describe FacultyStatusLadder do
  # A literal copy of the design's rank table (spec §1), kept independent of
  # FacultyStatusLadder::RANK so this spec fails if the implementation drifts
  # from the design rather than just mirroring whatever the code happens to say.
  RANKS = {
    'no_faculty_info' => 0,
    'incomplete_signup' => 1,
    'pending_sheerid' => 2,
    'sheerid_expired' => 2,
    'sheerid_error' => 2,
    'rejected_by_sheerid' => 2,
    'pending_faculty' => 3,
    'confirmed_faculty' => 4,
    'rejected_faculty' => 4
  }.freeze

  SHEERID_RANK = 2
  TERMINAL_RANK = 4

  def self.expected_allowed(from, to, source)
    from_rank = RANKS.fetch(from)
    to_rank = RANKS.fetch(to)

    return true if from == to
    return true if to_rank > from_rank
    return false if to_rank < from_rank

    case to_rank
    when SHEERID_RANK then true
    when TERMINAL_RANK then source == :salesforce
    else false
    end
  end

  describe '.allowed?' do
    it 'refuses an unknown target status regardless of source' do
      expect(described_class.allowed?(from: 'incomplete_signup', to: 'not_a_real_status',
                                      source: :accounts)).to eq(false)
      expect(described_class.allowed?(from: 'incomplete_signup', to: 'not_a_real_status',
                                      source: :salesforce)).to eq(false)
    end

    it 'raises on an unrecognized source' do
      expect {
        described_class.allowed?(from: 'incomplete_signup', to: 'pending_sheerid', source: :webhook)
      }.to raise_error(ArgumentError)
    end

    %i[accounts salesforce].each do |source|
      context "source: #{source}" do
        RANKS.keys.each do |from|
          RANKS.keys.each do |to|
            expected = expected_allowed(from, to, source)

            it "#{from} -> #{to} is #{expected}" do
              expect(described_class.allowed?(from: from, to: to, source: source)).to eq(expected)
            end
          end
        end
      end
    end
  end
end

describe User, '#advance_faculty_status!' do
  let(:user) {
    FactoryBot.create(:user, role: User::INSTRUCTOR_ROLE, faculty_status: User::INCOMPLETE_SIGNUP)
  }

  it 'applies an allowed move and logs faculty_status_advanced' do
    result = user.advance_faculty_status!(
      User::PENDING_SHEERID, source: :accounts, event_data: { verification_id: 'v1' }
    )

    expect(result).to eq(true)
    expect(user.reload.faculty_status).to eq(User::PENDING_SHEERID)

    log = SecurityLog.find_by!(event_type: :faculty_status_advanced, user: user)
    expect(log.event_data).to include(
      'from' => User::INCOMPLETE_SIGNUP, 'to' => User::PENDING_SHEERID,
      'source' => 'accounts', 'verification_id' => 'v1'
    )
  end

  it 'refuses a downgrade and logs faculty_status_downgrade_refused' do
    user.update!(faculty_status: User::CONFIRMED_FACULTY)

    result = user.advance_faculty_status!(User::INCOMPLETE_SIGNUP, source: :accounts)

    expect(result).to eq(false)
    expect(user.reload.faculty_status).to eq(User::CONFIRMED_FACULTY)

    log = SecurityLog.find_by!(event_type: :faculty_status_downgrade_refused, user: user)
    expect(log.event_data).to include(
      'from' => User::CONFIRMED_FACULTY, 'to' => User::INCOMPLETE_SIGNUP, 'source' => 'accounts'
    )
    expect(SecurityLog.where(event_type: :faculty_status_advanced, user: user)).to be_empty
  end

  it 'clears is_educator_pending_cs_verification when reaching a terminal status' do
    user.update!(faculty_status: User::PENDING_FACULTY, is_educator_pending_cs_verification: true)

    user.advance_faculty_status!(User::CONFIRMED_FACULTY, source: :salesforce)

    user.reload
    expect(user.faculty_status).to eq(User::CONFIRMED_FACULTY)
    expect(user.is_educator_pending_cs_verification).to eq(false)
  end

  it 'is a no-op that returns true and logs nothing when the status is unchanged' do
    user.update!(faculty_status: User::INCOMPLETE_SIGNUP)

    result = user.advance_faculty_status!(User::INCOMPLETE_SIGNUP, source: :accounts)

    expect(result).to eq(true)
    expect(SecurityLog.where(user: user,
                             event_type: [:faculty_status_advanced,
                                          :faculty_status_downgrade_refused])).to be_empty
  end
end
