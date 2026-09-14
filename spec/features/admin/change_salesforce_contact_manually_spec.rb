require 'rails_helper'

feature 'Change Salesforce contact manually', js: true do
  before(:each) do
    @admin_user = create_admin_user
    visit '/'
    complete_newflow_log_in_screen('admin')

    @target_user = FactoryBot.create(:user)

    visit "/admin/users/#{@target_user.id}/edit"
  end

  it 'can be removed' do
    @target_user.update_attribute(:salesforce_contact_id, 'something')
    visit "/admin/users/#{@target_user.id}/edit"
    fill_in 'user_salesforce_contact_id', with: 'remove'
    click_button 'Save'
    expect(page).to have_content('successfully updated')
    @target_user.reload
    expect(@target_user.salesforce_contact_id).to be_nil
  end

  it 'can be set if the Contact exists in SF' do
    contact = Salesforce::Records::Contact.new(
      id: '003AB000000XYZ', accounts_uuid: @target_user.uuid,
      master_record_id: nil, is_deleted: false
    )
    allow(Salesforce::Records::Contact).to receive(:find).with('003AB000000XYZ').and_return(contact)

    fill_in 'user_salesforce_contact_id', with: '003AB000000XYZ'
    click_button 'Save'
    expect(page).to have_content('successfully updated')
    @target_user.reload
    expect(@target_user.salesforce_contact_id).to eq '003AB000000XYZ'
  end

  it 'cannot be set if the Contact does not exist in SF' do
    @target_user.update_attribute(:salesforce_contact_id, 'original')
    allow(Salesforce::Records::Contact).to receive(:find).with('0010v000002Wo0qAAC').and_return(nil)

    visit "/admin/users/#{@target_user.id}/edit"
    fill_in 'user_salesforce_contact_id', with: '0010v000002Wo0qAAC'
    click_button 'Save'
    expect(page).to have_content("Can't find")
    @target_user.reload
    expect(@target_user.salesforce_contact_id).to eq 'original'
  end

  it 'cannot be set if the ID is malformed' do
    @target_user.update_attribute(:salesforce_contact_id, 'original')
    allow(Salesforce::Records::Contact).to receive(:find).with('somethingwonky')
      .and_raise(StandardError, 'malformed id')

    visit "/admin/users/#{@target_user.id}/edit"
    fill_in 'user_salesforce_contact_id', with: 'somethingwonky'
    click_button 'Save'
    expect(page).to have_content('Failed')
    @target_user.reload
    expect(@target_user.salesforce_contact_id).to eq 'original'
  end
end
