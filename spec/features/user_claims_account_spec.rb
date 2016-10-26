require 'rails_helper'

feature 'User claims an unclaimed account' do

  background { load 'db/seeds.rb' }

  scenario 'a new user signs up and completes profile when an account is waiting' do
    unclaimed_user = FindOrCreateUnclaimedUser.call(
      email:'unclaimeduser@example.com', username: 'therulerofallthings',
      password: "apassword", password_confirmation: "apassword"
    ).outputs[:user]
    visit '/'
    click_password_sign_up
    fill_in (t :"signup.new_account.email_address"), with: 'unclaimedtestuser@example.com'
    fill_in (t :"signup.new_account.username"), with: 'unclaimedtestuser'
    fill_in (t :"signup.new_account.password"), with: 'password'
    fill_in (t :"signup.new_account.confirm_password"), with: 'password'
    fill_in (t :"signup.new_account.first_name"), with: 'Test'
    fill_in (t :"signup.new_account.last_name"), with: 'User'
    agree_and_click_create

    new_user = User.find_by_username('unclaimedtestuser')
    expect(new_user).to_not be_nil

    expect{
      create_email_address_for new_user, "unclaimeduser@example.com", '4242'
      visit '/confirm?code=4242'
      expect(page).to have_content(t :"contact_infos.confirm.page_heading.success")
    }.to change(User, :count).by(-1)
    expect{
        unclaimed_user.reload
    }.to raise_error(ActiveRecord::RecordNotFound)

  end
end
