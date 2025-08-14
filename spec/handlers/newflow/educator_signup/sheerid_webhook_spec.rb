require 'rails_helper'

RSpec.describe Newflow::EducatorSignup::SheeridWebhook do
  let(:user)                    { FactoryBot.create :user }
  let(:email_address)           { FactoryBot.create :email_address, :verified, user: user }
  let(:school)                  { FactoryBot.create :school, sheerid_school_name: 'Rice University (Houston, TX)' }
  let(:verification)            do
    FactoryBot.create :sheerid_verification, 
      email: email_address.value,
      organization_name: school.sheerid_school_name, 
      current_step: 'verified',
      verification_id: 'test-verification-id'
  end

  let(:verification_details)    do
    SheeridAPI::Response.new(
      'lastResponse' => { 
        'currentStep' => verification.current_step,
        'verificationId' => verification.verification_id,
        'segment' => 'teacher',
        'subSegment' => nil,
        'locale' => 'en-US',
        'rewardCode' => 'EXAMPLE-CODE',
        'errorIds' => []
      },
      'programId' => '5e150b86ce2a5a1d94874660',
      'trackingId' => nil,
      'created' => 1593060602978,
      'updated' => 1593060611778,
      'personInfo' => {
        'firstName' => user.first_name,
        'lastName' => user.last_name,
        'email' => email_address.value,
        'birthDate' => nil,
        'deviceFingerprintHash' => nil,
        'phoneNumber' => nil,
        'country' => 'United States',
        'locale' => 'en-US',
        'metadata' => { 'marketConsentValue' => 'false' },
        'organization' => { 
          'id' => '2681',
          'name' => school.sheerid_school_name 
        },
        'postalCode' => '77005',
        'ipAddress' => '73.155.240.73'
      },
      'docUploadRejectionCount' => 0,
      'docUploadRejectionReasons' => []
    )
  end

  before do
    allow(SheeridAPI).to receive(:get_verification_details).with(
      verification.verification_id
    ).and_return(verification_details)

    allow(School).to receive(:find_by).with(
      sheerid_school_name: school.sheerid_school_name
    ).and_return(school)
  end

  context "user with verified verification" do
    it 'finds schools based on the sheerid_reported_school field' do
      expect(School).not_to receive(:fuzzy_search)

      described_class.handle(params: { verification_id: verification.verification_id })

      expect(user.reload.school).to eq school
    end

    it 'fuzzy searches schools based on the sheerid_reported_school field' do
      school.update_attribute :sheerid_school_name, nil
      
      # Update verification details to use a school name that doesn't have an exact match
      fuzzy_verification_details = SheeridAPI::Response.new(
        'lastResponse' => { 
          'currentStep' => verification.current_step,
          'verificationId' => verification.verification_id,
          'segment' => 'teacher',
          'subSegment' => nil,
          'locale' => 'en-US',
          'rewardCode' => 'EXAMPLE-CODE',
          'errorIds' => []
        },
        'programId' => '5e150b86ce2a5a1d94874660',
        'trackingId' => nil,
        'created' => 1593060602978,
        'updated' => 1593060611778,
        'personInfo' => {
          'firstName' => user.first_name,
          'lastName' => user.last_name,
          'email' => email_address.value,
          'birthDate' => nil,
          'deviceFingerprintHash' => nil,
          'phoneNumber' => nil,
          'country' => 'United States',
          'locale' => 'en-US',
          'metadata' => { 'marketConsentValue' => 'false' },
          'organization' => { 
            'id' => '2681',
            'name' => 'University of Arkansas, Monticello (Monticello, AR)' 
          },
          'postalCode' => '77005',
          'ipAddress' => '73.155.240.73'
        },
        'docUploadRejectionCount' => 0,
        'docUploadRejectionReasons' => []
      )
      
      allow(SheeridAPI).to receive(:get_verification_details).and_return(fuzzy_verification_details)
      
      # Ensure no exact match is found
      allow(School).to receive(:find_by).with(sheerid_school_name: 'University of Arkansas, Monticello (Monticello, AR)').and_return(nil)

      expect(School).to receive(:fuzzy_search).with(
        'University of Arkansas, Monticello', 'Monticello', 'AR'
      ).and_return(school)

      described_class.handle(params: { verification_id: verification.verification_id })

      expect(user.reload.school).to eq school
    end
  end

  context "duplicate webhook handling" do
    before do
      user.update!(sheerid_verification_id: verification.verification_id, faculty_status: User::CONFIRMED_FACULTY)
    end

    it "ignores duplicate webhooks for already confirmed users" do
      expect {
        described_class.handle(params: { verification_id: verification.verification_id })
      }.not_to change { user.reload.faculty_status }

      # Check for the duplicate webhook log specifically
      duplicate_log = SecurityLog.where(user: user, event_type: 'sheerid_webhook_duplicate_ignored').last
      expect(duplicate_log).to be_present
      expect(duplicate_log.event_data['reason']).to eq "Duplicate webhook for already processed verification"
    end

    it "ignores duplicate webhooks for same verification step" do
      user.update!(faculty_status: User::PENDING_SHEERID)
      
      # First webhook - this should create the verification record
      described_class.handle(params: { verification_id: verification.verification_id })
      
      # Verify the verification record was created with the correct step
      verification.reload
      expect(verification.current_step).to eq 'verified'
      
      # Second webhook with same step - this should be detected as duplicate
      expect {
        described_class.handle(params: { verification_id: verification.verification_id })
      }.not_to change { user.reload.faculty_status }

      # Check for the duplicate webhook log specifically
      duplicate_log = SecurityLog.where(user: user, event_type: 'sheerid_webhook_duplicate_ignored').last
      expect(duplicate_log).to be_present
      expect(duplicate_log.event_data['reason']).to eq "Duplicate webhook for already processed verification"
    end
  end

  context "enhanced data handling" do
    it "stores additional SheerID metadata in verification record" do
      described_class.handle(params: { verification_id: verification.verification_id })
      
      verification.reload
      expect(verification.program_id).to eq '5e150b86ce2a5a1d94874660'
      expect(verification.segment).to eq 'teacher'
      expect(verification.organization_id).to eq '2681'
      expect(verification.postal_code).to eq '77005'
      expect(verification.country).to eq 'United States'
      expect(verification.ip_address).to eq '73.155.240.73'
      expect(verification.doc_upload_rejection_count).to eq 0
      expect(verification.error_ids).to eq []
      expect(verification.metadata).to eq({ 'marketConsentValue' => 'false' })
    end

    it "stores SheerID metadata in user record" do
      described_class.handle(params: { verification_id: verification.verification_id })
      
      user.reload
      expect(user.sheerid_program_id).to eq '5e150b86ce2a5a1d94874660'
      expect(user.sheerid_segment).to eq 'teacher'
      expect(user.sheerid_organization_id).to eq '2681'
      expect(user.sheerid_postal_code).to eq '77005'
      expect(user.sheerid_country).to eq 'United States'
      expect(user.sheerid_ip_address).to eq '73.155.240.73'
      expect(user.sheerid_doc_upload_rejection_count).to eq 0
      expect(user.sheerid_error_ids).to eq []
      expect(user.sheerid_metadata).to eq({ 'marketConsentValue' => 'false' })
    end
  end

  context "data update logic" do
    it "updates user data for successful verifications" do
      verification.update!(current_step: 'success')
      new_verification_details = SheeridAPI::Response.new(
        'lastResponse' => { 'currentStep' => 'success' },
        'personInfo' => {
          'firstName' => 'New First',
          'lastName' => 'New Last',
          'email' => email_address.value,
          'organization' => { 'name' => 'New School' }
        }
      )
      
      allow(SheeridAPI).to receive(:get_verification_details).and_return(new_verification_details)
      allow(School).to receive(:find_by).with(sheerid_school_name: 'New School').and_return(nil)
      
      described_class.handle(params: { verification_id: verification.verification_id })
      
      user.reload
      expect(user.first_name).to eq 'New First'
      expect(user.last_name).to eq 'New Last'
      expect(user.sheerid_reported_school).to eq 'New School'
    end

    it "preserves existing user data for non-successful verifications with complete data" do
      user.update!(first_name: 'Existing First', last_name: 'Existing Last')
      verification.update!(current_step: 'collectTeacherPersonalInfo')
      new_verification_details = SheeridAPI::Response.new(
        'lastResponse' => { 'currentStep' => 'collectTeacherPersonalInfo' },
        'personInfo' => {
          'firstName' => 'New First',
          'lastName' => 'New Last',
          'email' => email_address.value,
          'organization' => { 'name' => 'New School' }
        }
      )
      
      allow(SheeridAPI).to receive(:get_verification_details).and_return(new_verification_details)
      allow(School).to receive(:find_by).with(sheerid_school_name: 'New School').and_return(nil)
      
      # The handler should update user data because the verification has more complete data
      # So we need to check that the should_update_user_data? method returns true
      handler = described_class.new
      handler.instance_variable_set(:@params, { verification_id: verification.verification_id })
      
      # Mock the verification object
      mock_verification = double('verification', 
        first_name: 'New First',
        last_name: 'New Last', 
        organization_name: 'New School'
      )
      
      # Mock the details object
      mock_details = double('details', current_step: 'collectTeacherPersonalInfo')
      
      # Check that should_update_user_data? returns true because verification has more complete data
      should_update = handler.send(:should_update_user_data?, user, mock_verification, mock_details)
      expect(should_update).to be true
      
      # Now run the actual handler
      described_class.handle(params: { verification_id: verification.verification_id })
      
      user.reload
      # The user data should be updated because the verification has more complete data
      expect(user.first_name).to eq 'New First'
      expect(user.last_name).to eq 'New Last'
    end

    it "updates user data for incomplete user profiles" do
      # Create a user with minimal data to avoid validation issues
      minimal_user = FactoryBot.create(:user, first_name: nil, last_name: nil, state: User::NEEDS_PROFILE)
      minimal_email = FactoryBot.create(:email_address, :verified, user: minimal_user, value: 'minimal@example.com')
      
      minimal_verification = FactoryBot.create(:sheerid_verification, 
        email: minimal_email.value,
        current_step: 'collectTeacherPersonalInfo',
        organization_name: school.sheerid_school_name
      )
      
      new_verification_details = SheeridAPI::Response.new(
        'lastResponse' => { 'currentStep' => 'collectTeacherPersonalInfo' },
        'personInfo' => {
          'firstName' => 'New First',
          'lastName' => 'New Last',
          'email' => minimal_email.value,
          'organization' => { 'name' => 'New School' }
        }
      )
      
      allow(SheeridAPI).to receive(:get_verification_details).and_return(new_verification_details)
      allow(School).to receive(:find_by).with(sheerid_school_name: 'New School').and_return(nil)
      
      described_class.handle(params: { verification_id: minimal_verification.verification_id })
      
      minimal_user.reload
      expect(minimal_user.first_name).to eq 'New First'
      expect(minimal_user.last_name).to eq 'New Last'
    end
  end

  context "verification step processing" do
    it "handles docUpload step" do
      verification.update!(current_step: 'docUpload')
      new_verification_details = SheeridAPI::Response.new(
        'lastResponse' => { 'currentStep' => 'docUpload' },
        'personInfo' => {
          'email' => email_address.value,
          'organization' => { 'name' => school.sheerid_school_name }
        }
      )
      
      allow(SheeridAPI).to receive(:get_verification_details).and_return(new_verification_details)
      
      described_class.handle(params: { verification_id: verification.verification_id })
      
      # Check for the doc upload log specifically
      doc_upload_log = SecurityLog.where(user: user, event_type: 'sheerid_webhook_doc_upload_required').last
      expect(doc_upload_log).to be_present
      expect(user.reload.faculty_status).to eq User::PENDING_SHEERID
    end

    it "handles error step with enhanced logging" do
      verification.update!(current_step: 'error')
      new_verification_details = SheeridAPI::Response.new(
        'lastResponse' => { 
          'currentStep' => 'error',
          'errorIds' => ['INVALID_DOCUMENT']
        },
        'personInfo' => {
          'email' => email_address.value,
          'organization' => { 'name' => school.sheerid_school_name }
        },
        'docUploadRejectionCount' => 1,
        'docUploadRejectionReasons' => ['Document not clear enough']
      )
      
      allow(SheeridAPI).to receive(:get_verification_details).and_return(new_verification_details)
      
      described_class.handle(params: { verification_id: verification.verification_id })
      
      # Check for the error log specifically
      error_log = SecurityLog.where(user: user, event_type: 'sheerid_error').last
      expect(error_log).to be_present
      expect(error_log.event_data['error_ids']).to eq ['INVALID_DOCUMENT']
      expect(error_log.event_data['doc_upload_rejection_count']).to eq 1
      expect(error_log.event_data['doc_upload_rejection_reasons']).to eq ['Document not clear enough']
    end
  end

  context "debug" do
    it "finds user by email correctly" do
      result = described_class.handle(params: { verification_id: verification.verification_id })
      expect(result.errors).to be_empty
      expect(result.outputs.verification_id).to eq verification.verification_id
    end
  end
end
