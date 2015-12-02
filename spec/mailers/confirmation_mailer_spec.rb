require "spec_helper"

describe ConfirmationMailer do
  let(:user) { FactoryGirl.create :user }
  let(:email) { FactoryGirl.create :email_address, value: 'to@example.org',
                                   user_id: user.id, confirmation_code: '1234' }

  describe "reminder" do
    let(:mail) { ConfirmationMailer.reminder email }

    it "renders the headers" do
      expect(mail.subject).to eq("[OpenStax] Reminder: please verify this email address")
      expect(mail.to).to eq(["to@example.org"])
      expect(mail.from).to eq(["noreply@openstax.org"])
    end

    it "renders the body" do
      expect(mail.body.encoded).to include("Hi #{user.casual_name}")
      expect(mail.body.encoded).to include('http://nohost/confirm?code=1234')
    end
  end

  describe "instructions" do
    let(:mail) { ConfirmationMailer.instructions email }

    it "renders the headers" do
      expect(mail.subject).to eq("[OpenStax] Please verify this email address")
      expect(mail.to).to eq(["to@example.org"])
      expect(mail.from).to eq(["noreply@openstax.org"])
    end

    it "renders the body" do
      expect(mail.body.encoded).to include("Hi #{user.casual_name}")
      expect(mail.body.encoded).to include('http://nohost/confirm?code=1234')
    end
  end

end
