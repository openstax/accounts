require 'rails_helper'

describe AuditApplicationUserRoles do
  let!(:application) { FactoryBot.create :doorkeeper_application }
  let!(:other_application) { FactoryBot.create :doorkeeper_application }

  it "returns the distinct, sorted roles in use for the given application" do
    FactoryBot.create :application_user, application: application, roles: ['instructor']
    FactoryBot.create :application_user, application: application, roles: ['student', 'instructor']
    FactoryBot.create :application_user, application: application, roles: ['student']

    outcome = described_class.call(application).outputs.roles
    expect(outcome).to eq ['instructor', 'student']
  end

  it "does not include roles from other applications" do
    FactoryBot.create :application_user, application: application, roles: ['instructor']
    FactoryBot.create :application_user, application: other_application, roles: ['librarian']

    outcome = described_class.call(application).outputs.roles
    expect(outcome).to eq ['instructor']
  end

  it "returns an empty array when no application_users have roles" do
    FactoryBot.create :application_user, application: application, roles: []

    outcome = described_class.call(application).outputs.roles
    expect(outcome).to eq []
  end
end
