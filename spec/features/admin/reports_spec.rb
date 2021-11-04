require 'rails_helper'
require 'byebug'

feature 'User reports page', js: true do
  before(:each) do
    @admin_user = create_admin_user
    visit '/i/login'
    complete_login_username_or_email_screen('admin', 'password')
  end

  it 'counts student users since the start of the fiscal year' do
    # Set up data with a student and instructor in two separate fiscal years
    Timecop.freeze(DateTime.parse("2019-06-30")) do
      User.student.create
      User.instructor.create
    end

    Timecop.freeze(DateTime.parse("2019-07-02")) do
      User.student.create
      User.instructor.create
    end

    # Go to the second of those fiscal years
    Timecop.freeze(DateTime.parse("2020-03-01")) do
      visit admin_reports_path
      expect(page).to have_content("Student accounts created since July 1: 1")
    end

    # Go to the next fiscal year
    Timecop.freeze(DateTime.parse("2020-07-02")) do
      visit admin_reports_path
      expect(page).to have_content("Student accounts created since July 1: 0")
    end
  end

  it 'counts student users created in the last week' do
    # Set up data with a student and instructor in two separate weeks
    Timecop.freeze(DateTime.now - (5.day)) do
      User.student.create
      User.student.create
      User.instructor.create
    end

    Timecop.freeze(DateTime.now - (2.week)) do
      User.student.create
      User.student.create
      User.student.create
      User.instructor.create
    end

    # run report
    visit admin_reports_path
    expect(page).to have_content("Student accounts created in the past week: 2")
  end
end
