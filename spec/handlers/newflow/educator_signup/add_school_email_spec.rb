require 'rails_helper'

module Newflow
  module EducatorSignup
    describe AddSchoolEmail, type: :handler do
      let(:user) { FactoryBot.create(:user) }

      before do
        FactoryBot.create(:email_address, value: 'j.delgado@gmail.com', verified: true, user: user)
      end

      let(:new_school_email) { 'j.delgado@rice.edu' }

      let(:params) do
        {
          school_email: {
            email: new_school_email
          }
        }
      end

      context 'when successful' do
        it 'adds a new, school-issued ContactInfo to the user without removing the existing one' do
          expect {
            described_class.call(params: params, user: user)
          }.to change(user.email_addresses, :count).from(1).to(2)

          added = user.email_addresses.find_by(value: new_school_email)
          expect(added).to be_present
          expect(added.is_school_issued).to eq true
          expect(added.verified).to eq false

          expect(user.email_addresses.find_by(value: 'j.delgado@gmail.com')).to be_present
        end

        it 'sends the standard confirmation email (PIN) to the new address' do
          expect_any_instance_of(NewflowMailer).to(
            receive(:signup_email_confirmation).once.and_call_original
          )
          described_class.call(params: params, user: user)
          perform_enqueued_jobs
        end
      end

      context 'when the user is anonymous' do
        let(:anonymous_user) { instance_double(User, is_anonymous?: true) }

        it 'is not authorized' do
          expect {
            described_class.call(params: params, user: anonymous_user)
          }.to raise_error(Lev::SecurityTransgression)
        end
      end

      context 'when the email is blank' do
        let(:params) { { school_email: { email: '' } } }

        it 'adds errors to the email input' do
          result = described_class.call(params: params, user: user)
          expect(result.errors).to have_offending_input(:email)
        end
      end

      context "when the email's domain has no MX records" do
        before do
          EmailDomainMxValidator.strategy = EmailDomainMxValidator::FakeStrategy.new(expecting: false)
        end

        let(:new_school_email) { 'j.delgado@not-a-real-school.edu' }

        it 'adds errors to the email input and does not create the ContactInfo' do
          expect {
            described_class.call(params: params, user: user)
          }.not_to change(user.email_addresses, :count)
        end
      end
    end
  end
end
