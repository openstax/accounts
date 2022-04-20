require 'rails_helper'

describe 'Terms', type: :feature, js: true do

  before(:each) do
    load 'db/seeds.rb'
  end

  scenario 'agrees to terms when signatures not present' do
    create_user('user','password', false)
    log_in('user','password')

    screenshot!
    expect(page).to have_content("Terms of Use")
    expect(page).to have_content(t :'terms.pose.contract_acceptance_required')
    find(:css, '#agreement_i_agree').click
    click_button (t :'terms.pose.agree')

    screenshot!
    expect(page).to have_content("Privacy Policy")
    expect(page).to have_content(t :'terms.pose.contract_acceptance_required')
    find(:css, '#agreement_i_agree').click
    click_button (t :'terms.pose.agree')

    expect_newflow_profile_page
  end

end
