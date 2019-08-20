require 'rails_helper'

RSpec.describe ExportUsersLastLoginDate, type: :routine do

  context "as a Lev output with student information" do
    let!(:user_1){ FactoryGirl.create :user }
    # let!(:some_other_user){ FactoryGirl.create :user }
    let!(:email_1){ FactoryGirl.create :email_address, user: user_1, verified: true }
    let!(:email_2){ FactoryGirl.create :email_address, user: user_1, verified: true }
    let!(:email_unverified){ FactoryGirl.create :email_address, user: user_1, verified: false }
    let!(:auth){ FactoryGirl.create :authentication, user: user_1 }
    let!(:security_log_entry){
        FactoryGirl.create :security_log, user: user_1, event_type: :sign_in_successful
    }
    let!(:auth){ FactoryGirl.create :authentication, user: user_1 }

    let!(:outputs){ described_class.call.outputs }
    let!(:first_output){ outputs.info[0] }

    it "includes last login date" do
      expect(first_output.last_login_at).to eq security_log_entry.created_at.strftime("%m/%d/%Y %I:%M%p %Z")
    end

    it "includes user's verified email addresses" do
      expect(first_output.emails).to eq "#{email_1.value}, #{email_2.value}"
    end

    context "as csv file with student information" do
      it "includes all the information it should" do
        Timecop.freeze(1.week.ago) do
          FactoryGirl.create :security_log, user: user_1, event_type: :sign_in_successful
        end

        with_csv_rows_to_match_w_consent_forms do |rows|
          headers = rows.first
          values = rows.second
          data = Hash[headers.zip(values)]

          expect(rows.count).to eq 2
          expect(data["Email(s)"].split(", ")).to match_array [email_1.value, email_2.value]
          expect(data["Last login date"]).to eq security_log_entry.created_at.strftime("%m/%d/%Y %I:%M%p %Z")
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
