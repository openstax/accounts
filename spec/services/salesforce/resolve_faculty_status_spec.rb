require 'rails_helper'

RSpec.describe Salesforce::ResolveFacultyStatus do
  let(:user) { FactoryBot.create(:user, faculty_status: :no_faculty_info) }

  describe '.from_signup' do
    it 'sets pending_faculty when profile complete and no SheerID record' do
      user.update!(is_profile_complete: true, sheerid_verification_id: nil)
      described_class.from_signup(user)
      expect(user.faculty_status).to eq('pending_faculty')
    end

    it 'sets status from SheerID when present' do
      user.update!(is_profile_complete: true, sheerid_verification_id: 'V1')
      v = SheeridVerification.create!(verification_id: 'V1', current_step: 'success')
      allow(SheeridVerification).to receive(:find_by).with(verification_id: 'V1').and_return(v)
      allow(v).to receive(:current_step_to_faculty_status).and_return(:confirmed_faculty)
      described_class.from_signup(user)
      expect(user.faculty_status).to eq('confirmed_faculty')
    end

    it 'sets incomplete_signup when profile incomplete' do
      user.update!(is_profile_complete: false)
      described_class.from_signup(user)
      expect(user.faculty_status).to eq('incomplete_signup')
    end
  end

  describe '.from_contact' do
    %w[confirmed_faculty pending_faculty rejected_faculty].each do |protected_status|
      it "does not overwrite #{protected_status} with no_faculty_info" do
        user.update!(faculty_status: protected_status)
        contact = Salesforce::Records::Contact.new(faculty_verified: nil)
        described_class.from_contact(user, contact)
        expect(user.faculty_status).to eq(protected_status)
      end

      it "does not overwrite #{protected_status} with incomplete_signup" do
        user.update!(faculty_status: protected_status)
        contact = Salesforce::Records::Contact.new(faculty_verified: 'incomplete_signup')
        described_class.from_contact(user, contact)
        expect(user.faculty_status).to eq(protected_status)
      end
    end

    it 'does not overwrite confirmed_faculty with pending_faculty' do
      user.update!(faculty_status: 'confirmed_faculty')
      contact = Salesforce::Records::Contact.new(faculty_verified: 'pending_faculty')
      described_class.from_contact(user, contact)
      expect(user.faculty_status).to eq('confirmed_faculty')
    end

    it 'updates from no_faculty_info to confirmed_faculty' do
      user.update!(faculty_status: 'no_faculty_info')
      contact = Salesforce::Records::Contact.new(faculty_verified: 'confirmed_faculty')
      described_class.from_contact(user, contact)
      expect(user.faculty_status).to eq('confirmed_faculty')
    end

    it 'raises and captures Sentry on unknown faculty_verified value' do
      user.update!(faculty_status: 'no_faculty_info')
      contact = Salesforce::Records::Contact.new(faculty_verified: 'weird_value', id: 'C1')
      expect(Sentry).to receive(:capture_message)
      expect {
        described_class.from_contact(user, contact)
      }.to raise_error(Salesforce::ResolveFacultyStatus::UnknownFacultyVerifiedError)
    end
  end
end
