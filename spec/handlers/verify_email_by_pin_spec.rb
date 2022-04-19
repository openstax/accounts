require 'rails_helper'

describe VerifyEmailByPin, type: :handler do
  context 'when success' do
    before { disable_sfdc_client }

    let(:educator_user) do
      FactoryBot.create(:user, state: 'unverified', source_application: source_app, receive_newsletter: false, role: :instructor)
    end

    let(:student_user) do
      FactoryBot.create(:user, state: 'unverified', source_application: source_app, receive_newsletter: false, role: :student)
    end

    let(:source_app) do
      FactoryBot.create(:doorkeeper_application)
    end

    let(:educator_email) do
      FactoryBot.create(:email_address, user: educator_user, value: Faker::Internet.email)
    end

    let(:student_email) do
      FactoryBot.create(:email_address, user: student_user, value: Faker::Internet.email)
    end

    let(:educator_params) do
      {
        confirm: {
          pin: educator_email.confirmation_pin
        }
      }
    end

    let(:student_params) do
      {
        confirm: {
          pin: student_email.confirmation_pin
        }
      }
    end

    it 'runs ActivateUser for educators' do
      expect_any_instance_of(ActivateUser).to receive(:exec)
      described_class.call(params: educator_params, email_address: educator_email)
    end

    it 'runs ActivateUser for students' do
      expect_any_instance_of(ActivateUser).to receive(:exec)
      described_class.call(params: student_params, email_address: student_email)
    end

    it 'sets the educator user (email owner) state to "activated"' do
      expect(educator_email.user.state).not_to eq('activated')
      described_class.call(params: educator_params, email_address: educator_email)
      expect(educator_email.user.state).to eq('activated')
    end

    it 'sets the student user (email owner) state to "activated"' do
      expect(student_email.user.state).not_to eq('activated')
      described_class.call(params: student_params, email_address: student_email)
      expect(student_email.user.state).to eq('activated')
    end

    it 'marks the educator user EmailAddress as verified' do
      expect(educator_email.verified).to be(false)
      described_class.call(params: educator_params, email_address: educator_email)
      expect(educator_email.verified).to be(true)
    end

    it 'marks the student user EmailAddress as verified' do
      expect(student_email.verified).to be(false)
      described_class.call(params: student_params, email_address: student_email)
      expect(student_email.verified).to be(true)
    end

    it 'updates a student status to :no_faculty_info' do
      described_class.call(params: student_params, email_address: student_email)
      expect(student_user.faculty_status).to eq('no_faculty_info')
    end
  end
end

