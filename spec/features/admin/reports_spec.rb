require 'rails_helper'

feature 'User reports page', js: true do
  before(:each) do
    create_admin_user.update!(role: User::ADMINISTRATOR_ROLE)
    visit '/'
    complete_login_username_or_email_screen('admin')
    complete_login_password_screen('password')
  end

  it 'counts student users created in the last week' do
    # Set up data with a student and instructor in two separate weeks
    Timecop.freeze(DateTime.now - (1.week - 1.second)) do
      User.student.create
      User.student.create
      User.instructor.create
    end

    Timecop.freeze(DateTime.now - (1.week + 1.second)) do
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
