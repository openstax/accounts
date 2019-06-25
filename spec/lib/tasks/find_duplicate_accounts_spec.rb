require 'rails_helper'

RSpec.describe "find_duplicate_accounts" do
  include_context "rake"

  after(:each) do
    FileUtils.rm_f 'duplicate_users_by_name.csv'
    FileUtils.rm_f 'duplicate_users_by_email.csv'
  end

  context "when it finds users with the same name (first name AND last name)" do
    let!(:user_1)          do
      FactoryBot.create :user, first_name: "Robert", last_name: "Martin", username: "RubyMaster"
    end
    let!(:same_name)       do
      FactoryBot.create :user, first_name: "robert", last_name: "martin", username: "RailsMaster"
    end

    let!(:same_first_name) do
      FactoryBot.create :user, first_name: user_1.first_name, last_name: "Ernser"
    end
    let!(:same_last_name)  do
      FactoryBot.create :user, first_name: "Kaci", last_name: user_1.last_name
    end
    let!(:different_name)  do
      FactoryBot.create :user, first_name: "Sandi", last_name: "Metz"
    end

    let!(:app_1_user_1)           { FactoryBot.create :application_user, user: user_1 }
    let!(:app_2_user_1)           { FactoryBot.create :application_user, user: user_1 }

    let!(:email_1_user_1)         { FactoryBot.create :email_address, user: user_1 }
    let!(:email_2_user_1)         do
      FactoryBot.create :email_address, user: user_1, verified: true
    end
    let!(:email_1_user_same_name) do
      FactoryBot.create :email_address, user: same_name, verified: true
    end

    let!(:authentications_1) do
      FactoryBot.create :authentication, user: user_1, provider: "google"
    end
    let!(:authentications_2) do
      FactoryBot.create :authentication, user: user_1, provider: "facebook"
    end

    let!(:sus_user_1)                        do
      FactoryBot.create :security_log, event_type: :sign_up_successful, user: user_1
    end
    let!(:help_req_1_user_1)                 do
      FactoryBot.create :security_log, event_type: :help_requested, user: user_1
    end
    let!(:help_req_2_user_1)                 do
      FactoryBot.create :security_log, event_type: :help_requested, user: user_1
    end
    let!(:help_req_fail_user_1)              do
      FactoryBot.create :security_log, event_type: :help_request_failed, user: user_1
    end
    let!(:sus_user_same_name)                do
      FactoryBot.create :security_log, event_type: :sign_up_successful, user: same_name
    end
    let!(:auth_transfer_fail_user_same_name) do
      FactoryBot.create :security_log, event_type: :authentication_transfer_failed,
                                        user: same_name
    end

    it "creates a csv file with the results" do
      call
      result = CSV.read('duplicate_users_by_name.csv', headers: true)

      expect(User.count).to eq 5
      expect(result.count).to eq 2
      expect(SecurityLog.count).to eq 6

      expect(result[0]["User First Name"]).to eq user_1.first_name
      expect(result[0]["User Last Name"]).to eq user_1.last_name
      expect(result[0]["Username"]).to eq "RubyMaster"
      expect(result[0]["Created At"]).to eq user_1.created_at.to_s
      expect(result[0]["Email Address(es)"].split(", ")).to match_array ["#{email_2_user_1.value} (verified)", "#{email_1_user_1.value} (NOT verified)"]
      expect(result[0]["User ID"]).to eq user_1.id.to_s
      expect(result[0]["Signup Successful?"]).to eq "On #{sus_user_1.created_at}"
      expect(result[0]["Reset Password Help Requested?"].split(" and ")).to match_array ["On #{help_req_1_user_1.created_at}", "On #{help_req_2_user_1.created_at}"]
      expect(result[0]["Help Request Failed?"]).to eq "On #{help_req_fail_user_1.created_at}"
      expect(result[0]["Authentication Transfer Failed?"]).to be_empty
      expect(result[0]["Applications"].split(", ")).to match_array [user_1.applications.first.name, user_1.applications.second.name]
      expect(result[0]["Authentications"].split(", ")).to match_array ["Facebook", "Google"]


      expect(result[1]["User First Name"]).to eq same_name.first_name
      expect(result[1]["User Last Name"]).to eq same_name.last_name
      expect(result[1]["Username"]).to eq "RailsMaster"
      expect(result[1]["Created At"]).to eq same_name.created_at.to_s
      expect(result[1]["Email Address(es)"]).to eq "#{email_1_user_same_name.value} (verified)"
      expect(result[1]["User ID"]).to eq same_name.id.to_s
      expect(result[1]["Signup Successful?"]).to eq "On #{sus_user_same_name.created_at}"
      expect(result[1]["Reset Password Help Requested?"]).to be_empty
      expect(result[1]["Help Request Failed?"]).to be_empty
      expect(result[1]["Authentication Transfer Failed?"]).to eq "On #{auth_transfer_fail_user_same_name.created_at}"
      expect(result[1]["Applications"]).to be_empty
      expect(result[1]["Authentications"]).to be_empty
    end
  end

  context "when it finds 0 users with the same name" do
    let!(:a_user) { FactoryBot.create :user, first_name: "Robert", last_name: "Martin" }
    let!(:another_user) { FactoryBot.create :user }

    it "creates a csv file with 0 results" do
      call

      expect(User.count).to eq 2
      result = CSV.read('duplicate_users_by_name.csv', headers: true)

      expect(result.count).to eq 0
    end
  end

  context "when it finds users with the same email address" do
    let!(:user_1) do
      FactoryBot.create :user, first_name: "John", last_name: "Lock", username: "RubyKing"
    end
    let!(:user_2) do
      FactoryBot.create :user, first_name: "Jack", last_name: "Shepherd", username: "RailsKing"
    end
    let!(:email_1) do
      FactoryBot.create :email_address, user: user_1, verified: true
    end
    let!(:same_email_diff_user) do
      email = FactoryBot.create :email_address, user: user_2
      ContactInfo.where(id: email.id).update_all(value: email_1.value)
      email.reload
    end

    let!(:authentication) { FactoryBot.create :authentication, user: user_1, provider: "facebook" }

    let!(:cool)   { FactoryBot.create :user }
    let!(:person) { FactoryBot.create :user }

    let!(:sus_user_1) do
      FactoryBot.create :security_log, event_type: :sign_up_successful, user: user_1
    end
    let!(:help_req_1_user_1) do
      FactoryBot.create :security_log, event_type: :help_requested, user: user_1
    end
    let!(:help_req_2_user_1) do
      FactoryBot.create :security_log, event_type: :help_requested, user: user_1
    end
    let!(:help_req_fail_user_1) do
      FactoryBot.create :security_log, event_type: :help_request_failed, user: user_1
    end
    let!(:sus_user_2) do
      FactoryBot.create :security_log, event_type: :sign_up_successful, user: user_2
    end
    let!(:auth_transfer_fail_user_2) do
      FactoryBot.create :security_log, event_type: :authentication_transfer_failed, user: user_2
    end

    let!(:app_1_user_1) { FactoryBot.create :application_user, user: user_1 }
    let!(:app_2_user_1) { FactoryBot.create :application_user, user: user_1 }

    it "creates a csv file with the results" do
      call
      result = CSV.read('duplicate_users_by_email.csv', headers: true)

      expect(User.count).to eq 4
      expect(result.count).to eq 2
      expect(SecurityLog.count).to eq 6

      expect(result[0]["Email Address"]).to eq "#{email_1.value} (verified)"
      expect(result[0]["Created At"]).to eq email_1.created_at.to_s
      expect(result[0]["ContactInfo ID"]).to eq email_1.id.to_s
      expect(result[0]["User First Name"]).to eq user_1.first_name
      expect(result[0]["User Last Name"]).to eq user_1.last_name
      expect(result[0]["User ID"]).to eq user_1.id.to_s
      expect(result[0]["Username"]).to eq "RubyKing"
      expect(result[0]["Applications"].split(", ")).to match_array [user_1.applications.first.name, user_1.applications.second.name]
      expect(result[0]["Signup Successful?"]).to eq "On #{sus_user_1.created_at}"
      expect(result[0]["Reset Password Help Requested?"].split(" and ")).to match_array ["On #{help_req_1_user_1.created_at}", "On #{help_req_2_user_1.created_at}"]
      expect(result[0]["Help Request Failed?"]).to eq "On #{help_req_fail_user_1.created_at}"
      expect(result[0]["Authentication Transfer Failed?"]).to be_empty
      expect(result[0]["Authentications"]).to eq "Facebook"

      expect(result[1]["Email Address"]).to eq "#{same_email_diff_user.value} (NOT verified)"
      expect(result[1]["Created At"]).to eq same_email_diff_user.created_at.to_s
      expect(result[1]["ContactInfo ID"]).to eq same_email_diff_user.id.to_s
      expect(result[1]["User First Name"]).to eq user_2.first_name
      expect(result[1]["User Last Name"]).to eq user_2.last_name
      expect(result[1]["User ID"]).to eq user_2.id.to_s
      expect(result[1]["Username"]).to eq "RailsKing"
      expect(result[1]["Applications"]).to be_empty
      expect(result[1]["Signup Successful?"]).to eq "On #{sus_user_2.created_at}"
      expect(result[1]["Reset Password Help Requested?"]).to be_empty
      expect(result[1]["Help Request Failed?"]).to be_empty
      expect(result[1]["Authentication Transfer Failed?"]).to eq "On #{auth_transfer_fail_user_2.created_at}"
      expect(result[1]["Authentications"]).to be_empty
    end
  end

  context "when it finds 0 users with the same email" do
    let!(:email_1) { FactoryBot.create :email_address }
    let!(:email_2) { FactoryBot.create :email_address }

    it "creates a csv file with 0 results" do
      call

      expect(User.count).to eq 2
      expect(EmailAddress.count).to eq 2
      result = CSV.read('duplicate_users_by_email.csv', headers: true)

      expect(result.count).to eq 0
    end
  end

end
