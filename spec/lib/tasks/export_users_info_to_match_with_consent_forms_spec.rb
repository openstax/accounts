require 'rails_helper'

RSpec.describe ExportUsersInfoToMatchWithConsentForms, type: :routine do

  context "as a Lev output with student information" do
    let!(:user_1){ FactoryGirl.create :user, username: "TonyStark", first_name: "Tony", last_name: "Stark" }
    let!(:some_other_user){ FactoryGirl.create :user }
    let!(:email_1){ FactoryGirl.create :email_address, user: user_1 }
    let!(:email_2){ FactoryGirl.create :email_address, user: user_1 }

    let!(:outputs){ described_class.call.outputs }
    let!(:first_output){ outputs.info[0] }

    it "includes the user id" do
      expect(first_output.user_id).to eq user_1.id
    end

    it 'includes student\'s school id ("student identifier")' do
      expect(first_output.emails.split(", ")).to match_array user_1.contact_infos.map(&:value)
    end

    it "includes name" do
      expect(first_output.name).to eq "Tony Stark"
    end

    it "includes username" do
      expect(first_output.username).to eq "TonyStark"
    end

    context "as csv file with student information" do
      it "includes all the information it should" do
        with_csv_rows_to_match_w_consent_forms do |rows|
          headers = rows.first
          values = rows.second
          data = Hash[headers.zip(values)]

          expect(rows.count).to eq 3
          expect(data["Email(s)"].split(", ")).to match_array user_1.contact_infos.map(&:value)
          expect(data["User ID"]).to eq user_1.id.to_s
          expect(data["Name"]).to eq "Tony Stark"
          expect(data["Username"]).to eq "TonyStark"
        end
      end
    end
  end

end

def with_csv_rows_to_match_w_consent_forms(&block)
  expect_any_instance_of(described_class).to receive(:remove_exported_files) do |routine|
    filepath = routine.send :filename
    expect(File.exists?(filepath)).to be true
    expect(filepath.ends_with? '.csv').to be true
    rows = CSV.read(filepath)
    block.call(rows)
  end

  described_class.call
end
