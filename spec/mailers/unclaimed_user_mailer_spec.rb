require 'rails_helper'

describe UnclaimedUserMailer, type: :mailer do
  let(:user) { FactoryGirl.create :user_with_emails, emails_count:1, state: 'unclaimed' }
  let(:contact_info){ user.contact_infos.first }
  let(:mail) { UnclaimedUserMailer.welcome user.contact_infos.first }

  describe "welcome" do

    it "sets headers properly" do
      expect(mail.to).to eq([contact_info.value])
      expect(mail.subject).to eq("[OpenStax] You have been invited to join OpenStax")
    end

    it "sets the link with the confirmation code" do
      expect(mail.body.encoded).to include(
        confirm_unclaimed_url(code: contact_info.confirmation_code)
      )
    end


  end

end
