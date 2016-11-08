require 'rails_helper'

xfeature 'Skipped terms are respected', js: true do

  background do
    load 'db/seeds.rb'
    @app_with_skip    = FactoryGirl.create :doorkeeper_application, skip_terms: true
    @app_without_skip = FactoryGirl.create :doorkeeper_application, skip_terms: false
  end

  scenario 'when signing up/in under one application WITHOUT skip' do
    visit_authorize_uri(@app_without_skip) # simulate arriving from an app
    click_password_sign_up

    # No skipping
    expect(page).to have_content(t :"signup.new_account.have_read_terms_and_agree_html",
                                   terms_of_use: 'Terms of Use',
                                   privacy_policy: 'Privacy Policy')

    fill_in (t :"signup.new_account.first_name"), with: 'Bob'
    fill_in (t :"signup.new_account.last_name"), with: 'Dillon'
    fill_in (t :"signup.new_account.email_address"), with: 'bob@example.com'
    fill_in (t :"signup.new_account.username"), with: 'bob'
    fill_in (t :"signup.new_account.password"), with: 'password'
    fill_in (t :"signup.new_account.confirm_password"), with: 'password'
    agree_and_click_create

    expect(page).to have_no_missing_translations
    click_on (t :"layouts.application_header.sign_out")

    # While the user is signed out, a new contract version is published
    make_new_contract_version

    visit_authorize_uri(@app_without_skip)

    expect(page).to have_no_missing_translations
    fill_in (t :"sessions.new.username_or_email"), with: 'bob'
    fill_in (t :"sessions.new.password"), with: 'password'
    click_on (t :"sessions.new.sign_in")

    # Gotta sign the new version
    expect(current_path).to eq "/terms/pose"
  end

  scenario 'when signing up in under one application WITH skip' do
    visit_authorize_uri(@app_with_skip)

    click_password_sign_up

    # Skipping
    expect(page).not_to have_content(t :"signup.new_account.have_read_terms_and_agree_html",
                                       terms_of_use: 'Terms of Use',
                                       privacy_policy: 'Privacy Policy')

    fill_in (t :"signup.new_account.first_name"), with: 'Bob'
    fill_in (t :"signup.new_account.last_name"), with: 'Dillon'
    fill_in (t :"signup.new_account.email_address"), with: 'bob@example.com'
    fill_in (t :"signup.new_account.username"), with: 'bob'
    fill_in (t :"signup.new_account.password"), with: 'password'
    fill_in (t :"signup.new_account.confirm_password"), with: 'password'
    click_on (t :"signup.new_account.create_account")

    click_on (t :"layouts.application_header.sign_out")

    # While the user is signed out, a new contract version is published
    make_new_contract_version

    visit_authorize_uri(@app_with_skip)

    fill_in (t :"sessions.new.username_or_email"), with: 'bob'
    fill_in (t :"sessions.new.password"), with: 'password'
    click_on (t :"sessions.new.sign_in")

    # Shouldn't have to sign the new version
    expect(current_path).to eq "/oauth/authorize"
  end

  scenario 'no skipping when signing up/in without a particular application' do
    visit '/'

    click_password_sign_up

    # No skipping
    expect(page).to have_content(t :"signup.new_account.have_read_terms_and_agree_html",
                                   terms_of_use: 'Terms of Use',
                                   privacy_policy: 'Privacy Policy')

    fill_in (t :"signup.new_account.first_name"), with: 'Bob'
    fill_in (t :"signup.new_account.last_name"), with: 'Dillon'
    fill_in (t :"signup.new_account.email_address"), with: 'bob@example.com'
    fill_in (t :"signup.new_account.username"), with: 'bob'
    fill_in (t :"signup.new_account.password"), with: 'password'
    fill_in (t :"signup.new_account.confirm_password"), with: 'password'
    agree_and_click_create

    click_on (t :"layouts.application_header.sign_out")

    # While the user is signed out, a new contract version is published
    make_new_contract_version

    visit '/'

    fill_in (t :"sessions.new.username_or_email"), with: 'bob'
    fill_in (t :"sessions.new.password"), with: 'password'
    click_on (t :"sessions.new.sign_in")

    # Gotta sign the new version
    expect(current_path).to eq "/terms/pose"
  end

end
