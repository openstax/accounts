require 'rails_helper'

describe 'Terms', type: :feature, js: true do

  before(:each) do
    load 'db/seeds.rb'
  end

  scenario 'agrees to terms when signatures not present' do
    create_user('user@example.com')
    log_in('user','password')

    expect(page).to have_content("Terms of Use")
    expect(page).to have_content(t :'terms.pose.contract_acceptance_required')
    find(:css, '#agreement_i_agree').click
    click_button (t :'terms.pose.agree')

    expect(page).to have_content("Privacy Policy")
    expect(page).to have_content(t :'terms.pose.contract_acceptance_required')
    find(:css, '#agreement_i_agree').click
    click_button (t :'terms.pose.agree')
  end

end
