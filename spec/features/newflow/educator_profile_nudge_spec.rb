require 'rails_helper'

feature 'Educator profile nudge', :js do
  before do turn_on_educator_feature_flag end

  let(:password) { 'password' }
  let(:email) { Faker::Internet.unique.email(domain: '@rice.edu') }

  def create_confirmed_but_incomplete_educator(email)
    user = create_newflow_user(email, password, nil, nil, 'instructor')
    user.update!(
      faculty_status: User::CONFIRMED_FACULTY,
      sheerid_verification_id: Faker::Alphanumeric.alphanumeric(number: 24),
      is_profile_complete: false
    )
    user
  end

  context 'a confirmed_faculty educator with an incomplete profile' do
    let!(:user) { create_confirmed_but_incomplete_educator(email) }

    it 'is redirected to step 4 exactly once, then gets a banner on later visits instead' do
      # First login: the one-time redirect.
      visit(newflow_login_path)
      complete_newflow_log_in_screen(email, password)
      wait_for_successful_log_in

      expect(page).to have_current_path(educator_profile_form_path)

      user.reload
      expect(user.profile_nudge_redirected_at).to be_present
      expect(
        SecurityLog.where(user: user, event_type: :profile_nudge_redirected).count
      ).to eq(1)

      # Second login: no more forced redirect to step 4.
      visit(signout_path)
      wait_for_log_in_form

      newflow_log_in_user(email, password)
      wait_for_successful_log_in

      expect(page).not_to have_current_path(educator_profile_form_path)

      # The account page shows the banner instead, and logs its one-time
      # "shown" event.
      visit(profile_newflow_path)
      expect(page).to have_content(I18n.t(:"profile_nudge_banner.heading"))
      expect(
        SecurityLog.where(user: user, event_type: :profile_nudge_banner_shown).count
      ).to eq(1)

      # A second render does not create a second SecurityLog row.
      visit(profile_newflow_path)
      expect(
        SecurityLog.where(user: user, event_type: :profile_nudge_banner_shown).count
      ).to eq(1)

      # The banner's link goes to step 4.
      click_on(I18n.t(:"profile_nudge_banner.finish_button"))
      expect(page).to have_current_path(educator_profile_form_path)
    end

    it 'lets the banner be dismissed for the rest of the session' do
      visit(newflow_login_path)
      complete_newflow_log_in_screen(email, password)
      wait_for_successful_log_in

      visit(signout_path)
      wait_for_log_in_form
      newflow_log_in_user(email, password)
      wait_for_successful_log_in

      visit(profile_newflow_path)
      expect(page).to have_content(I18n.t(:"profile_nudge_banner.heading"))

      click_on(I18n.t(:"profile_nudge_banner.dismiss_button"))
      expect(page).to have_no_content(I18n.t(:"profile_nudge_banner.heading"))

      visit(profile_newflow_path)
      expect(page).to have_no_content(I18n.t(:"profile_nudge_banner.heading"))
    end
  end

  context 'a student' do
    let!(:user) do
      user = create_newflow_user(email, password, nil, nil, 'student')
      user
    end

    it 'never sees the nudge redirect or the banner' do
      visit(newflow_login_path)
      complete_newflow_log_in_screen(email, password)
      wait_for_successful_log_in

      expect(page).not_to have_current_path(educator_profile_form_path)

      visit(profile_newflow_path)
      expect(page).to have_no_content(I18n.t(:"profile_nudge_banner.heading"))
    end
  end

  context 'a profile-complete educator' do
    let!(:user) do
      user = create_newflow_user(email, password, nil, nil, 'instructor')
      user.update!(
        faculty_status: User::CONFIRMED_FACULTY,
        sheerid_verification_id: Faker::Alphanumeric.alphanumeric(number: 24),
        is_profile_complete: true
      )
      user
    end

    it 'never sees the nudge redirect or the banner' do
      visit(newflow_login_path)
      complete_newflow_log_in_screen(email, password)
      wait_for_successful_log_in

      expect(page).not_to have_current_path(educator_profile_form_path)

      visit(profile_newflow_path)
      expect(page).to have_no_content(I18n.t(:"profile_nudge_banner.heading"))
    end
  end
end
