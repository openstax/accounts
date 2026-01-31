require 'rails_helper'
require 'support/fake_salesforce'

feature 'Change Salesforce contact manually', js: true do
  include FakeSalesforce::SpecHelpers

  before(:each) do
    stub_salesforce!

    @admin_user = create_admin_user
    visit '/'
    complete_newflow_log_in_screen('admin')

    @target_user = FactoryBot.create(:user)

    visit "/admin/users/#{@target_user.id}/edit"
  end

  it 'can be removed' do
    @target_user.update_attribute(:salesforce_contact_id, 'something')
    fill_in 'user_salesforce_contact_id', with: 'remove'
    click_button 'Save'
    expect(page).to have_content('successfully updated')
    @target_user.reload
    expect(@target_user.salesforce_contact_id).to be_nil
  end

  it 'can be set if the Contact exists in SF' do
    contact = fake_salesforce_contact(
      id: 'TESTCONTACT001',
      first_name: 'Test',
      last_name: 'Contact',
      email: 'test@example.com'
    )
    fill_in 'user_salesforce_contact_id', with: contact.id
    click_button 'Save'
    expect(page).to have_content('successfully updated')
    @target_user.reload
    expect(@target_user.salesforce_contact_id).to eq contact.id
  end

  it 'cannot be set if the Contact does not exist in SF' do
    @target_user.update_attribute(:salesforce_contact_id, 'original')
    fill_in 'user_salesforce_contact_id', with: '0010v000002Wo0qAAC'
    click_button 'Save'
    expect(page).to have_content("Can't find")
    @target_user.reload
    expect(@target_user.salesforce_contact_id).to eq "original"
  end

  it 'cannot be set if the ID is malformed' do
    @target_user.update_attribute(:salesforce_contact_id, 'original')
    # Simulate a malformed ID causing an error
    allow(OpenStax::Salesforce::Remote::Contact).to receive(:find).with('somethingwonky').and_raise(StandardError)
    fill_in 'user_salesforce_contact_id', with: 'somethingwonky'
    click_button 'Save'
    expect(page).to have_content('Failed')
    @target_user.reload
    expect(@target_user.salesforce_contact_id).to eq "original"
  end
end
