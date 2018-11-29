require 'rails_helper'

describe 'Apply for faculty access', type: :feature, js: true do

  before(:each) do
    @user = create_user('user')
    @user.state = 'activated'
    @user.save!
  end

  scenario "anonymous user asked to log in" do
    visit faculty_access_apply_path(r: capybara_url(external_app_for_specs_path))
    screenshot!
    expect_sign_in_page
    expect(page).to have_no_content("Sign up")
    complete_login_username_or_email_screen('user')
    complete_login_password_screen('password')
    complete_faculty_access_apply_screen(
        role: :instructor,
        first_name: "Jimmy",
        last_name: "Tudeski",
        email: "howdy@ho.com",
        phone_number: "000-0000",
        school: "Rice University",
        url: "http://www.rice.edu",
        subjects: ["Biology", "Principles of Macroeconomics"],
        newsletter: true,
    )
    expect(page).to have_content(t :"faculty_access.pending.page_heading")
    click_button(t :"faculty_access.pending.ok")
    expect(page.current_url).to eq(capybara_url(external_app_for_specs_path))
  end

  context "chooses instructor role" do
    before(:each) {
      disable_sfdc_client
      visit '/'
      log_in('user','password')
      visit faculty_access_apply_path(r: capybara_url(external_app_for_specs_path))
    }

    scenario "leaves fields blank" do
      complete_faculty_access_apply_screen(
        role: :instructor,
        first_name: "",
        last_name: "",
        email: "",
        phone_number: "",
        school: "",
        url: "",
        num_students: "",
        using_openstax: "",
        newsletter: true,
      )

      screenshot!
      expect(page).to have_content(t :"faculty_access.apply.page_heading")
      [:first_name, :last_name, :email, :phone_number, :school, :url, :using_openstax].each do |var|
        expect(page).to have_content(error_msg FacultyAccessApplyInstructor, var, :blank)
      end
      expect(find('#apply_first_name').value).not_to eq @user.first_name
      expect(find('#apply_last_name').value).not_to eq @user.last_name
      expect(page).to have_content(error_msg FacultyAccessApplyInstructor, :num_students, :not_a_number)
    end

    scenario "email taken" do
      create_email_address_for(create_user('other_user'), 'in@use.com')

      complete_faculty_access_apply_screen(
        role: :instructor,
        email: "in@use.com",
        phone_number: "000-0000",
        school: "Rice",
        url: "google.com",
        num_students: "30",
        using_openstax: "primary",
        newsletter: true,
      )

      screenshot!
      expect(page).to have_content(t :"faculty_access.apply.page_heading")
      expect(page).to have_content(t :"faculty_access.apply.email_in_use")
    end

    scenario "success" do
      allow(Settings::Salesforce).to receive(:push_leads_enabled) { true }

      expect_any_instance_of(PushSalesforceLead)
        .to receive(:exec)
        .with(hash_including(
          subject: "Biology;Macro Econ",
          email: "howdy@ho.com",
          user: @user
        )
      )

      call_embedded_screenshots do
        complete_faculty_access_apply_screen(
          role: :instructor,
          first_name: "Jimmy",
          last_name: "Tudeski",
          email: "howdy@ho.com",
          phone_number: "000-0000",
          school: "Rice University",
          url: "http://www.rice.edu",
          num_students: "30",
          using_openstax: "primary",
          subjects: ["Biology", "Principles of Macroeconomics"],
          newsletter: true,
        )
      end

      expect(@user.contact_infos.unverified.map(&:value)).to eq ["howdy@ho.com"]

      screenshot!
      expect(page).to have_content(t :"faculty_access.pending.page_heading")
      expect(page).to have_no_missing_translations

      click_button(t :"faculty_access.pending.ok")

      expect(page.current_url).to eq(capybara_url(external_app_for_specs_path))
    end
  end

end
