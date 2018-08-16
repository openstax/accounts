require 'rails_helper'

describe SignInHelpMailer, type: :mailer do

  context "multiple_accounts" do
    let(:mail) { SignInHelpMailer.multiple_accounts email_address: "bob@bob.com", usernames: ["bob", "bobby"] }

    it 'renders the headers' do
      expect(mail.subject).to eq('Your OpenStax usernames')
      expect(mail.header['to'].to_s).to eq("bob@bob.com")
      expect(mail.from).to eq(['noreply@openstax.org'])
    end

    it 'renders the body' do
      expect(mail.body.encoded).to include('Your email address, <b>bob@bob.com</b>')
      expect(mail.body.encoded).to include('are: <b>bob</b> and <b>bobby</b>')
    end
  end

  context "reset_password" do
    let(:user) { OpenStruct.new(full_name: "Big Bob", login_token: "1234", casual_name: "Big") }
    let(:mail) { SignInHelpMailer.reset_password user: user, email_address: "bob@bob.com" }

    it 'renders the headers' do
      expect(mail.subject).to eq('Reset your OpenStax password')
      expect(mail.header['to'].value).to eq("\"Big Bob\" <bob@bob.com>")
      expect(mail.from).to eq(['noreply@openstax.org'])
    end

    it 'renders the body' do
      expect(mail.body.encoded).to include('Hi Big,')
      expect(mail.body.encoded).to include('password/reset?token=1234')
    end
  end

  context "add_password" do
    let(:user) { OpenStruct.new(full_name: "Big Bob", login_token: "1234", casual_name: "Big") }
    let(:mail) { SignInHelpMailer.add_password user: user, email_address: "bob@bob.com" }

    it 'renders the headers' do
      expect(mail.subject).to eq('Add a password to your OpenStax account')
      expect(mail.header['to'].value).to eq("\"Big Bob\" <bob@bob.com>")
      expect(mail.from).to eq(['noreply@openstax.org'])
    end

    it 'renders the body' do
      expect(mail.body.encoded).to include('Hi Big,')
      expect(mail.body.encoded).to include('password/add?token=1234')
    end
  end

end
