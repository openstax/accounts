require "spec_helper"

describe UnclaimedUserMailer do
  let(:user) { FactoryGirl.create :user_with_emails, emails_count:1, state: 'unclaimed' }

  let(:mail) { UnclaimedUserMailer.welcome user.contact_infos.first }

  describe "welcome" do

    it "delivers" do
      expect(mail.subject).to eq("[OpenStax] You have been invited to join OpenStax")
    end

    it "sets the link to signup when it the user doensn't have an identity" do
      expect(mail.body).to include(signup_url)
    end

    context "an user with an identity" do
      before{ FactoryGirl.create :identity, user: user }
      it "sets the link to login" do
        expect(mail.body).to include(login_url)
      end
    end

  end

end
