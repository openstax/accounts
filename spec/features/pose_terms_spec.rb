require 'rails_helper'

describe 'Terms', type: :feature, js: true do

  before(:each) do
    load 'db/seeds.rb'
  end

  scenario 'agrees to terms when signatures not present' do
    create_user('user','password', false)
    newflow_log_in_user('user','password')

    max_terms_acceptance_retries = 3

    max_terms_acceptance_retries.times do
      break if page.has_current_path?(profile_newflow_path, wait: 1)

      screenshot!
      expect(page).to have_content("To continue, please review and agree to the following site terms")
      expect(page).to have_content(t :"terms.pose.contract_acceptance_required")
      check 'agreement_i_agree'
      click_button (t :"terms.pose.agree")
      wait_for_animations
      wait_for_ajax
    end

    expect_newflow_profile_page
  end

end
