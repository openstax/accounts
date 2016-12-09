require 'rails_helper'

describe DevMailer, type: :mailer do

  describe "#inspect" do
    it 'has basic header pretty prints object' do
      mail = DevMailer.inspect_object object: [{a: 2}, {b: "yo yo yo"}],
                                      to: "bob@example.com",
                                      subject: "Howdy"

      expect(mail.header['to'].to_s).to eq('bob@example.com')
      expect(mail.from).to eq(["noreply@openstax.org"])
      expect(mail.subject).to eq "[OpenStax] Howdy"
      expect(mail.body.encoded).to eq(
        "[\r\n  [0] {\r\n    :a => 2\r\n  },\r\n  [1] {\r\n    :b => \"yo yo yo\"\r\n  }\r\n]\r\n"
      )
    end

    it 'does not explode with nil object' do
      expect{
        DevMailer.inspect_object object: nil, to: "bob@example.com", subject: "Howdy"
      }.not_to raise_error
    end

    it 'does not explode without a to and uses a default' do
      expect{
        mail = (DevMailer.inspect_object object: nil, subject: "Howdy")
        expect(mail.to).not_to be_empty
      }.not_to raise_error
    end
  end

end
