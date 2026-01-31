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
    fill_in 'user_salesforce_contact_id', with: 'remove'
    click_button 'Save'
    expect(page).to have_content('successfully updated')
    @target_user.reload
    expect(@target_user.salesforce_contact_id).to be_nil
  end

  it 'can be set if the Contact exists in SF' do
    valid_contact_id = '0030v000002Wo0qAAC'
    mock_contact = double('Contact', id: valid_contact_id)
    allow(OpenStax::Salesforce::Remote::Contact).to receive(:find).with(valid_contact_id).and_return(mock_contact)
    
    fill_in 'user_salesforce_contact_id', with: valid_contact_id
    click_button 'Save'
    expect(page).to have_content('successfully updated')
    @target_user.reload
    expect(@target_user.salesforce_contact_id).to eq valid_contact_id
  end

  it 'cannot be set if the Contact does not exist in SF' do
    @target_user.update_attribute(:salesforce_contact_id, 'original')
    invalid_contact_id = '0010v000002Wo0qAAC'
    allow(OpenStax::Salesforce::Remote::Contact).to receive(:find).with(invalid_contact_id).and_return(nil)
    
    fill_in 'user_salesforce_contact_id', with: invalid_contact_id
    click_button 'Save'
    expect(page).to have_content("Can't find")
    @target_user.reload
    expect(@target_user.salesforce_contact_id).to eq "original"
  end

  it 'cannot be set if the ID is malformed' do
    @target_user.update_attribute(:salesforce_contact_id, 'original')
    malformed_id = 'somethingwonky'
    allow(OpenStax::Salesforce::Remote::Contact).to receive(:find).with(malformed_id).and_raise(StandardError.new('Invalid ID'))
    
    fill_in 'user_salesforce_contact_id', with: malformed_id
    click_button 'Save'
    expect(page).to have_content('Failed')
    @target_user.reload
    expect(@target_user.salesforce_contact_id).to eq "original"
  end
end
