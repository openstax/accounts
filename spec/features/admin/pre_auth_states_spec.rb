require 'rails_helper'
require 'byebug'

feature 'Admin PreAuthStates page' do

  context 'as an admin user' do
    before(:each) do
      @admin_user = create_admin_user
      visit '/i/login'
      complete_login_username_or_email_screen('admin', 'password')
    end

    it "works" do
      Timecop.freeze(4.weeks.ago) do
        FactoryBot.create :contact_info, value: "a@a.com", verified: false
      end
      Timecop.freeze(1.9.weeks.ago) do
        FactoryBot.create :contact_info, value: "b@b.com", verified: false
      end
      Timecop.freeze(0.9.weeks.ago) do
        FactoryBot.create :contact_info, value: "c@c.com", verified: false
      end
      FactoryBot.create :contact_info, value: "d@d.com", verified: false

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
