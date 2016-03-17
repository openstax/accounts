require 'rails_helper'

feature 'Skipped terms are respected', js: true do

  background do
    @app_with_skip    = FactoryGirl.create :doorkeeper_application, skip_terms: true
    @app_without_skip = FactoryGirl.create :doorkeeper_application, skip_terms: false
  end

  scenario 'when signing up/in under one application WITHOUT skip' do
    visit_authorize_uri(@app_without_skip) # simulate arriving from an app
    click_on 'Create password account'

    # No skipping
    expect(page).to have_content('I have read')

    fill_in 'First Name', with: 'Bob'
    fill_in 'Last Name', with: 'Dillon'
    fill_in 'Email Address', with: 'bob@example.com'
    fill_in 'Username', with: 'bob'
    fill_in 'Password *', with: 'password'
    fill_in 'Confirm Password', with: 'password'
    check 'register_i_agree'
    click_on 'Register'

    click_on 'Sign out'

    # While the user is signed out, a new contract version is published
    make_new_contract_version

    visit_authorize_uri(@app_without_skip)

    fill_in 'Username', with: 'bob'
    fill_in 'Password', with: 'password'
    click_on 'Sign in'

    # Gotta sign the new version
    expect(current_path).to eq "/terms/pose"
  end

  scenario 'when signing up in under one application WITH skip' do
    visit_authorize_uri(@app_with_skip)

    click_on 'Create password account'

    # Skipping
    expect(page).not_to have_content('I have read')

    fill_in 'First Name', with: 'Bob'
    fill_in 'Last Name', with: 'Dillon'
    fill_in 'Email Address', with: 'bob@example.com'
    fill_in 'Username', with: 'bob'
    fill_in 'Password *', with: 'password'
    fill_in 'Confirm Password', with: 'password'
    click_on 'Register'

    click_on 'Sign out'

    # While the user is signed out, a new contract version is published
    make_new_contract_version

    visit_authorize_uri(@app_with_skip)

    fill_in 'Username', with: 'bob'
    fill_in 'Password', with: 'password'
    click_on 'Sign in'

    # Shouldn't have to sign the new version
    expect(current_path).to eq "/oauth/authorize"
  end

  scenario 'no skipping when signing up/in without a particular application' do
    visit '/'

    click_on 'Create password account'

    # No skipping
    expect(page).to have_content('I have read')

    fill_in 'First Name', with: 'Bob'
    fill_in 'Last Name', with: 'Dillon'
    fill_in 'Email Address', with: 'bob@example.com'
    fill_in 'Username', with: 'bob'
    fill_in 'Password *', with: 'password'
    fill_in 'Confirm Password', with: 'password'
    check 'register_i_agree'
    click_on 'Register'

    click_on 'Sign out'

    # While the user is signed out, a new contract version is published
    make_new_contract_version

    visit '/'

    fill_in 'Username', with: 'bob'
    fill_in 'Password', with: 'password'
    click_on 'Sign in'

    # Gotta sign the new version
    expect(current_path).to eq "/terms/pose"
  end

end
