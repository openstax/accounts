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
    visit admin_reports_path
    expect(page).to have_content("Student accounts created since July 1: 1")
    # Go to the next fiscal year
    Timecop.freeze(DateTime.parse("2020-07-02"))
    visit admin_reports_path
    expect(page).to have_content("Student accounts created since July 1: 0")
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
    expect(page).to have_content("Student accounts created in the past week: 1")
  end

  example 'How many people start the account creation process versus how many finish it?' do
    years = (2016..2020).to_a
    years.each_with_index do |year, index|
        Timecop.freeze(Time.local(year) + 1.day) do
          (index * 1).times { FactoryBot.create(:pre_auth_state) }
          (index * 2).times { User.create(state: User::ACTIVATED) }
        end
    end

    visit admin_reports_path

    expect(page).to have_content('2018: 2 started / 4 finished = 50.0%')
    expect(page).to have_content('2019: 3 started / 6 finished = 50.0%')
    expect(page).to have_content('2020: 4 started / 9 finished = 44.44%') # 8 finished plus the admin
  end

  context "What's the average time someone spends signing up (started the process but did not finish)?" do
    example 'with no users' do
      visit admin_reports_path
      expect(page).to have_content("What's the average time someone spends signing up (started the process but did not finish)? unknown")
    end

    example 'with users' do
      first = User.create(state: User::UNVERIFIED)
      Timecop.freeze(DateTime.now - 2.hours) do
        first.update(state: 'activated')
      end

      second = User.create(state: User::UNVERIFIED)
      Timecop.freeze(DateTime.now - 4.hours) do
        second.update(state: 'activated')
      end

      visit admin_reports_path

      expect(page).to have_content("What's the average time someone spends signing up (started the process but did not finish)? about 3 hours")
    end
  end
end
