require 'rails_helper'

describe ListApplicationUsersWithRole do
  let!(:application) { FactoryBot.create :doorkeeper_application }
  let!(:other_application) { FactoryBot.create :doorkeeper_application }

  let!(:instructor) { FactoryBot.create :user, first_name: 'Ida', last_name: 'Instructor' }
  let!(:student) { FactoryBot.create :user, first_name: 'Sam', last_name: 'Student' }
  let!(:both) { FactoryBot.create :user, first_name: 'Bo', last_name: 'Both' }

  before do
    FactoryBot.create :application_user, application: application, user: instructor,
                                          roles: ['instructor']
    FactoryBot.create :application_user, application: application, user: student,
                                          roles: ['student']
    FactoryBot.create :application_user, application: application, user: both,
                                          roles: ['instructor', 'student']
  end

  it "returns only users with the given role for the given application" do
    outcome = described_class.call(application, 'instructor').outputs.users
    expect(outcome.to_a).to contain_exactly(instructor, both)
  end

  it "does not include users who have a different role" do
    outcome = described_class.call(application, 'instructor').outputs.users
    expect(outcome.to_a).not_to include(student)
  end

  it "does not include users of that role from other applications" do
    other_instructor = FactoryBot.create :user, first_name: 'Otto', last_name: 'Other'
    FactoryBot.create :application_user, application: other_application, user: other_instructor,
                                          roles: ['instructor']

    outcome = described_class.call(application, 'instructor').outputs.users
    expect(outcome.to_a).not_to include(other_instructor)
  end

  it "returns an empty relation when no users have the given role" do
    outcome = described_class.call(application, 'librarian').outputs.users
    expect(outcome.to_a).to eq []
  end
end
