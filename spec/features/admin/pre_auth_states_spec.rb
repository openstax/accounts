require 'rails_helper'

feature 'Admin PreAuthStates page' do

  context 'as an admin user' do
    before(:each) do
      @admin_user = create_admin_user
      visit '/'
      complete_login_username_or_email_screen('admin')
      complete_login_password_screen('password')
    end

    it "works" do
      Timecop.freeze(4.weeks.ago) do
        FactoryGirl.create :pre_auth_state, contact_info_value: "a@a.com"
      end
      Timecop.freeze(1.9.weeks.ago) do
        FactoryGirl.create :pre_auth_state, contact_info_value: "b@b.com"
      end
      Timecop.freeze(0.9.weeks.ago) do
        FactoryGirl.create :pre_auth_state, contact_info_value: "c@c.com"
      end
      FactoryGirl.create :pre_auth_state, contact_info_value: "d@d.com"

      visit '/admin/pre_auth_states'

      expect(page).to have_content("d@d.com")
      expect(page).to have_no_content("c@c.com")

      click_link "1 week"

      expect(page).to have_content(/d@d\.com.*c@c\.com/)
      expect(page).to have_no_content("b@b.com")

      click_link "2 weeks"

      expect(page).to have_content(/d@d\.com.*c@c\.com.*b@b\.com/)
      expect(page).to have_no_content("a@a.com")

      click_link "All"

      expect(page).to have_content(/d@d\.com.*c@c\.com.*b@b\.com.*a@a\.com/)
    end
  end

end
