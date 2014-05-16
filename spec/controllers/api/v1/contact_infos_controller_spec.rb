require "spec_helper"

describe Api::V1::ContactInfosController, :type => :api, :version => :v1 do

  let!(:untrusted_application)     { FactoryGirl.create :doorkeeper_application }
  let!(:trusted_application)     { FactoryGirl.create :doorkeeper_application, :trusted }
  let!(:user_1)          { FactoryGirl.create :user, :terms_agreed }
  let!(:user_2)          { FactoryGirl.create :user_with_emails, :terms_agreed,
                             first_name: 'Bob', last_name: 'Michaels' }

  let!(:user_1_token)    { FactoryGirl.create :doorkeeper_access_token, 
                                              application: untrusted_application, 
                                              resource_owner_id: user_1.id }

  let!(:user_2_token)    { FactoryGirl.create :doorkeeper_access_token, 
                                              application: untrusted_application, 
                                              resource_owner_id: user_2.id }

  let!(:trusted_application_token) { FactoryGirl.create :doorkeeper_access_token, 
                                                application: trusted_application, 
                                                resource_owner_id: nil }

  let!(:untrusted_application_token) { FactoryGirl.create :doorkeeper_access_token, 
                                                application: untrusted_application, 
                                                resource_owner_id: nil }

  let!(:new_email) { {type: 'EmailAddress', value: 'frank@sinatra.com', verified: true} }

  describe "create" do

    it "should let a user create himself a new contact info" do

      expect {
        api_post :create, user_1_token, raw_post_data: new_email, parameters: { user_id: user_1.id }
      }.to change{user_1.contact_infos.count}.from(0).to(1)

      expect(response.code).to eq('201')
      
      expect(user_1.contact_infos.first.type).to eq 'EmailAddress'
      expect(user_1.contact_infos.first.value).to eq 'frank@sinatra.com'
      expect(user_1.contact_infos.first.verified).to be_false
    end

    it "should let an app create a contact info for a user" do
      expect {
        api_post :create, user_1_token, raw_post_data: new_email
      }.to change{user_1.contact_infos(true).count}.from(0).to(1)
    end

    it "should not let a user create a contact info for another user" do
      expect {
        api_post :create, user_2_token, raw_post_data: new_email, parameters: { user_id: user_1.id }
      }.to_not change{user_1.contact_infos(true).count}
    end
  end

  describe "destroy" do
    it "should let a user delete a contact info" do
      expect {
        api_delete :destroy, user_2_token, raw_post_data: {
                                             type: 'EmailAddress', 
                                             value: 'frank@sinatra.com',
                                             verified: true
                                           }, 
                                           parameters: { id: user_2.contact_infos.first.id }
      }.to change{user_2.contact_infos(true).count}.from(2).to(1)

      expect(response.code).to eq('204')
    end
  end

  describe "show" do
    it "should let a user get his contact info" do
      info = user_2.contact_infos.first

      api_get :show, user_2_token, parameters: { id: info.id }
      expect(response.code).to eq('200')
      expect(response.body).to eq({id: info.id, type: info.type, value: info.value, verified: info.verified}.to_json)
    end

    it "should not let an untrusted application get contact info" do
      info = user_2.contact_infos.first
      expect{api_get :show, untrusted_application_token, parameters: {
        id: info.id }}.to raise_error(SecurityTransgression)
    end
  end

  describe "resend_confirmation" do
    it "should let a user resend confirmation" do
      AddEmailToUser.call('blah@example.com', user_1)
      contact_info = user_1.contact_infos.first
      expect(contact_info.verified).to be_false
      time_before = Time.now
      api_put :resend_confirmation, user_1_token, parameters: {id: contact_info.id}
      expect(response.status).to eq(204)
      contact_info.reload
      expect(contact_info.confirmation_sent_at).to be > time_before
    end
  end

end                                                