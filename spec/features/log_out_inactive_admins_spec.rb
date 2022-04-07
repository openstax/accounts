require 'rails_helper'

feature 'Log out Admins after 30 minutes of non-admin activity', js: true do
  let!(:login_time) { DateTime.now }

  before(:each) do
    allow_any_instance_of(ApplicationController).to receive(:is_real_production_site?).and_return(true)
    Timecop.freeze(login_time)
  end

  after(:each) do
    Timecop.return
  end

  context "logged-in admin user" do
    before(:each) do
      create_admin_user
      log_in 'admin'
    end

    context "within 30mins from login" do
      scenario 'user IS NOT redirected to login screen when admin feature is accessed' do
        visit admin_feature_url
        Timecop.travel(login_time + 29.minutes)
        visit admin_feature_url

        expect(page).to have_current_path(admin_feature_url)
        expect(page).to have_content('Accounts Admin Console')
      end
    end
    context "that HAS NOT accessed any admin features in the past 30mins" do
      scenario "user IS redirected to login screen when admin feature is accessed" do
        # Security feature!
        visit admin_feature_url
        expect(page).to have_current_path(admin_feature_url)
        expect(page).to have_content('Accounts Admin Console')
        Timecop.travel(login_time + 5.minutes)
        visit non_admin_feature_url
        Timecop.travel(login_time + 31.minutes)
        visit admin_feature_url

        expect(page).to have_current_path(login_path)
      end
    end
    context "that HAS accessed any admin features in the past 30mins" do
      scenario "user IS NOT redirected to login screen when admin feature is accessed" do
        Timecop.travel(login_time + 5.minutes)
        visit admin_feature_url
        Timecop.travel(login_time + 26.minutes)
        visit admin_feature_url

        expect(page).to have_current_path(admin_feature_url)
        expect(page).to have_content('Accounts Admin Console')
      end
    end

    context "after 30mins from login" do
      scenario "user IS redirected to login screen when admin feature is accessed" do
        # Security feature!
        Timecop.travel(login_time + 31.minutes)
        visit admin_feature_url

        expect(page).to have_current_path(login_path)
      end
    end
    context "when accessing only non-admin features" do
      scenario "user IS NOT redirected to login" do
        Timecop.travel(login_time + 5.minutes)
        visit non_admin_feature_url
        Timecop.travel(login_time + 26.minutes)
        visit non_admin_feature_url
        Timecop.travel(login_time + 31.minutes)
        visit non_admin_feature_url

        expect(page).to have_current_path(non_admin_feature_url)
      end
    end
  end

  context "logged-in non-admin user" do
    before(:each) do
      create_user 'user'
      log_in 'user'
    end

    context "when accessing only non-admin features" do
      scenario "user IS NOT redirected to login" do
        Timecop.travel(login_time + 5.minutes)
        visit non_admin_feature_url
        Timecop.travel(login_time + 26.minutes)
        visit non_admin_feature_url
        Timecop.travel(login_time + 31.minutes)
        visit non_admin_feature_url

        expect(page).to have_current_path(non_admin_feature_url)
      end
    end
    scenario "cannot access admin features" do
      visit admin_feature_url

      expect(page).to have_current_path(admin_feature_url)
      expect(page).to have_no_content('Accounts Admin Console')

      visit '/' # Needed to prevent failures on specs after this one for some reason
    end
    scenario "can access visitor pages" do
      visit visitor_page_url

      expect(page).to have_current_path(visitor_page_url)
    end
    scenario "can access user features" do
      visit non_admin_feature_url

      expect(page).to have_current_path(non_admin_feature_url)
    end
  end

  context "non-logged-in anonymous user" do
    scenario "cannot access admin features" do
      visit admin_feature_url

      expect(page).to have_no_current_path(admin_feature_url)
    end
    scenario "cannot access user features" do
      visit non_admin_feature_url

      expect(page).to have_current_path(newflow_login_path)
    end
    scenario "can access visitor pages" do
      visit visitor_page_url

      expect(page).to have_current_path(visitor_page_url)
    end
  end

  context "non-admin user logs in" do
    scenario "later someone makes him/her an admin" do
      current_user = create_user 'user'
      log_in 'user'
      expect(current_user.is_administrator?).to eq false

      Timecop.travel(login_time + 31.minutes)
      visit non_admin_feature_url

      current_user.is_administrator = true
      current_user.save
      expect(current_user.is_administrator?).to eq true

      visit non_admin_feature_url
      expect(page).to have_current_path(non_admin_feature_url)

      visit admin_feature_url
      expect(page).to have_current_path(admin_feature_url)
      expect(page).to have_content('Accounts Admin Console')
    end
  end

  def admin_feature_url
    admin_security_log_path
  end

  def non_admin_feature_url
    "/profile"
  end

  def visitor_page_url
    "/copyright"
  end
end
