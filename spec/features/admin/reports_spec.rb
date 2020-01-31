require 'rails_helper'
feature 'User reports page', js: true do
  before(:each) do
    create_admin_user
    visit '/'
    complete_login_username_or_email_screen('admin')
    complete_login_password_screen('password')
  end
  it 'counts student users since the start of the fiscal year' do
    # Set up data with a student and instructor in two separate fiscal years
    Timecop.freeze(DateTime.parse("2019-06-30"))
    User.student.create
    User.instructor.create
    Timecop.freeze(DateTime.parse("2019-07-02"))
    User.student.create
    User.instructor.create
    # Go to the second of those fiscal years
    Timecop.freeze(DateTime.parse("2020-03-01"))
    visit '/admin/reports'
    expect(page).to have_content("Student accounts created since July 1: 1")
    # Go to the next fiscal year
    Timecop.freeze(DateTime.parse("2020-07-02"))
    visit '/admin/reports'
    expect(page).to have_content("Student accounts created since July 1: 0")
  end
end