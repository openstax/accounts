require 'rails_helper'
require 'vcr_helper'

RSpec.describe "Change Salesforce contact manually", vcr: VCR_OPTS do

  before(:all) do
    @proxy = SalesforceProxy.new
  end

  before(:each) do
    load_salesforce_user

    @admin_user = create_admin_user
    visit '/'
    complete_login_username_or_email_screen('admin')
    complete_login_password_screen('password')

    @target_user = FactoryGirl.create(:user)

    visit "/admin/users/#{@target_user.id}/edit"
  end

  it 'can be removed' do
    @target_user.update_attribute(:salesforce_contact_id, 'something')
    fill_in 'user_salesforce_contact_id', with: 'remove'
    click_button 'Save'
    @target_user.reload
    expect(@target_user.salesforce_contact_id).to be_nil
  end

  it 'can be set if the Contact exists in SF' do
    contact = @proxy.new_contact
    fill_in 'user_salesforce_contact_id', with: contact.id
    click_button 'Save'
    @target_user.reload
    expect(@target_user.salesforce_contact_id).to eq contact.id
  end

  it 'cannot be set if the Contact does not exist in SF' do
    @target_user.update_attribute(:salesforce_contact_id, 'original')
    fill_in 'user_salesforce_contact_id', with: 'somethingNewNotInSF'
    click_button 'Save'
    @target_user.reload
    expect(@target_user.salesforce_contact_id).to eq "original"
  end

end
