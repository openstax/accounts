require 'rails_helper'
require 'vcr_helper'

RSpec.feature "Change Salesforce contact manually", vcr: VCR_OPTS, :type => :feature, js: true do
  #TODO: review this spec during refactor to verify usefulness and if it should be reenabled.
  pending("Not currently working in CI but works locally, skipping specs for now")
  before(:all) do
    VCR.use_cassette('Admin/sf_setup', VCR_OPTS) do
      @proxy = SalesforceProxy.new
      @proxy.setup_cassette
    end
  end

  before(:each) do
    @admin_user = create_admin_user
    visit '/'
    log_in 'admin@openstax.org'

    @target_user = FactoryBot.create(:user)

    visit "/admin/users/#{@target_user.id}/edit"
  end

  xit 'can be removed' do
    @target_user.update_attribute(:salesforce_contact_id, 'something')
    fill_in 'user_salesforce_contact_id', with: 'remove'
    click_button 'Save'
    @target_user.reload
    expect(@target_user.salesforce_contact_id).to be_nil
  end

  xit 'can be set if the Contact exists in SF' do
    contact = @proxy.new_contact
    fill_in 'user_salesforce_contact_id', with: contact.id
    click_button 'Save'
    @target_user.reload
    expect(@target_user.salesforce_contact_id).to eq contact.id
  end

  xit 'cannot be set if the Contact does not exist in SF' do
    @target_user.update_attribute(:salesforce_contact_id, 'original')
    fill_in 'user_salesforce_contact_id', with: '0010v000002Wo0qAAC'
    click_button 'Save'
    @target_user.reload
    expect(@target_user.salesforce_contact_id).to eq "original"
  end

  xit 'cannot be set if the ID is of malformed' do
    @target_user.update_attribute(:salesforce_contact_id, 'original')
    fill_in 'user_salesforce_contact_id', with: 'somethingwonky'
    click_button 'Save'
    @target_user.reload
    expect(@target_user.salesforce_contact_id).to eq "original"
  end
end
