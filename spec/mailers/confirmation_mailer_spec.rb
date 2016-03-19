require 'rails_helper'

describe ConfirmationMailer, type: :mailer do
  let(:user) { FactoryGirl.create :user, first_name: 'John', last_name: 'Doe', suffix: 'Jr.' }
  let(:email) { FactoryGirl.create :email_address, value: 'to@example.org',
                                   user_id: user.id, confirmation_code: '1234' }

  describe "reminder" do
    let(:mail) { ConfirmationMailer.reminder email }

    it "renders the headers" do
      expect(mail.subject).to eq("[OpenStax] Reminder: please verify this email address")
      expect(mail.header['to'].to_s).to eq('"John Doe Jr." <to@example.org>')
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
      expect(mail.header['to'].to_s).to eq('"John Doe Jr." <to@example.org>')
      expect(mail.from).to eq(["noreply@openstax.org"])
    end

    it "renders the body" do
      expect(mail.body.encoded).to include("Hi #{user.casual_name}")
      expect(mail.body.encoded).to include('http://nohost/confirm?code=1234')
    end
  end

end
