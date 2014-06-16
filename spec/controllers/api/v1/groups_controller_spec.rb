require "spec_helper"

describe Api::V1::GroupsController, :type => :api, :version => :v1 do

  let!(:group_1) { FactoryGirl.create :group }
  let!(:group_2) { FactoryGirl.create :group }
  let!(:user_1)       { group_1.group_users.first.user }
  let!(:user_2)       { group_2.group_users.first.user }
  let!(:user_3)       { FactoryGirl.create :user }

  let!(:untrusted_application) { FactoryGirl.create :doorkeeper_application }

  let!(:user_1_token) { FactoryGirl.create :doorkeeper_access_token,
                        application: untrusted_application,
                        resource_owner_id: user_1.id }
  let!(:user_2_token) { FactoryGirl.create :doorkeeper_access_token,
                        application: untrusted_application,
                        resource_owner_id: user_2.id }
  let!(:user_3_token) { FactoryGirl.create :doorkeeper_access_token,
                        application: untrusted_application,
                        resource_owner_id: user_3.id }
  let!(:untrusted_application_token) { FactoryGirl.create :doorkeeper_access_token,
                                       application: untrusted_application,
                                       resource_owner_id: nil }

  it '' do
  end

end