require 'rails_helper'

feature 'Admin signup state page' do

  context 'as an admin user' do
    before(:each) do
      @admin_user = create_admin_user
      visit '/'
      complete_login_username_or_email_screen('admin')
      complete_login_password_screen('password')
    end

    it "works" do
      Timecop.freeze(4.weeks.ago) { FactoryGirl.create :signup_state, contact_info_value: "a@a.com" }
      Timecop.freeze(1.9.weeks.ago) { FactoryGirl.create :signup_state, contact_info_value: "b@b.com" }
      Timecop.freeze(0.9.weeks.ago) { FactoryGirl.create :signup_state, contact_info_value: "c@c.com" }
      FactoryGirl.create :signup_state, contact_info_value: "d@d.com"

      visit '/admin/signup_states'

      expect(page).to have_content("d@d.com")
      expect(page).not_to have_content("c@c.com")

      click_link "1 week"

      expect(page).to have_content(/d@d\.com.*c@c\.com/)
      expect(page).not_to have_content("b@b.com")

      click_link "2 weeks"

      expect(page).to have_content(/d@d\.com.*c@c\.com.*b@b\.com/)
      expect(page).not_to have_content("a@a.com")

      click_link "All"

      expect(page).to have_content(/d@d\.com.*c@c\.com.*b@b\.com.*a@a\.com/)
    end
  end

end
