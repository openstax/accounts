require 'spec_helper'

describe ApplicationUsersUpdatedAfter do
  let!(:application) { FactoryGirl.create :doorkeeper_application }
  
  let!(:user_1) { FactoryGirl.create :user,
                                     first_name: 'John',
                                     last_name: 'Stravinsky',
                                     username: 'jstrav' }
  let!(:user_2) { FactoryGirl.create :user,
                                     first_name: 'Mary',
                                     last_name: 'Mighty',
                                     full_name: 'Mary Mighty',
                                     username: 'mary' }
  let!(:user_3) { FactoryGirl.create :user,
                                     first_name: 'John',
                                     last_name: 'Stead',
                                     username: 'jstead' }

  before(:each) do
    [user_1, user_2].each do |user|
      FactoryGirl.create :application_user, user: user, application: application
    end
  end

  it "should not return results if application is nil" do
    outcome = ApplicationUsersUpdatedAfter.call(nil, nil).outputs.application_users
    expect(outcome).to eq nil
  end

  it "should return all users if no time is specified" do
    outcome = ApplicationUsersUpdatedAfter.call(application, nil).outputs.application_users.all
    expect(outcome).to eq [user_1.application_users.first,
                           user_2.application_users.first]
  end

  it "should return users updated after the specified time" do
    sleep 0.1
    user_2.first_name = 'May'
    user_2.save!
    outcome = ApplicationUsersUpdatedAfter.call(application, user_1.updated_at.to_f + 0.1).outputs.application_users.all
    expect(outcome).to eq [user_2.application_users.first]
  end

end