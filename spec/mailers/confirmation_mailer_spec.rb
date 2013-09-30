require "spec_helper"

describe ConfirmationMailer do
  describe "reminder" do
    let(:mail) { ConfirmationMailer.reminder }

    it "renders the headers" do
      mail.subject.should eq("Reminder")
      mail.to.should eq(["to@example.org"])
      mail.from.should eq(["from@example.com"])
    end

    it "renders the body" do
      mail.body.encoded.should match("Hi")
    end
  end

  describe "instructions" do
    let(:mail) { ConfirmationMailer.instructions }

    it "renders the headers" do
      mail.subject.should eq("Instructions")
      mail.to.should eq(["to@example.org"])
      mail.from.should eq(["from@example.com"])
    end

    it "renders the body" do
      mail.body.encoded.should match("Hi")
    end
  end

end
