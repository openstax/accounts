require 'rails_helper'
require 'rake'

RSpec.describe 'doorkeeper:cleanup' do
  include_context 'rake'

  before(:all) do
    current_time = Time.current

    Doorkeeper::AccessGrant.delete_all

    FactoryBot.create :doorkeeper_access_grant, expires_in: 10.minutes,
                                                 created_at: current_time - 1.year
    FactoryBot.create :doorkeeper_access_grant, expires_in: 10.minutes,
                                                 created_at: current_time - 6.months
    FactoryBot.create :doorkeeper_access_grant, expires_in: 10.minutes,
                                                 created_at: current_time - 3.months
    FactoryBot.create :doorkeeper_access_grant, expires_in: 10.minutes,
                                                 created_at: current_time - 30.days
    FactoryBot.create :doorkeeper_access_grant, expires_in: 10.minutes,
                                                 created_at: current_time - 2.weeks
    FactoryBot.create :doorkeeper_access_grant, expires_in: 10.minutes,
                                                 created_at: current_time

    FactoryBot.create :doorkeeper_access_grant, revoked_at: current_time - 1.year
    FactoryBot.create :doorkeeper_access_grant, revoked_at: current_time - 6.months
    FactoryBot.create :doorkeeper_access_grant, revoked_at: current_time - 3.months
    FactoryBot.create :doorkeeper_access_grant, revoked_at: current_time - 30.days
    FactoryBot.create :doorkeeper_access_grant, revoked_at: current_time - 2.weeks
    FactoryBot.create :doorkeeper_access_grant, revoked_at: current_time

    Doorkeeper::AccessToken.delete_all

    FactoryBot.create :doorkeeper_access_token, expires_in: 10.minutes,
                                                 created_at: current_time - 1.year
    FactoryBot.create :doorkeeper_access_token, expires_in: 10.minutes,
                                                 created_at: current_time - 6.months
    FactoryBot.create :doorkeeper_access_token, expires_in: 10.minutes,
                                                 created_at: current_time - 3.months
    FactoryBot.create :doorkeeper_access_token, expires_in: 10.minutes,
                                                 created_at: current_time - 30.days
    FactoryBot.create :doorkeeper_access_token, expires_in: 10.minutes,
                                                 created_at: current_time - 2.weeks
    FactoryBot.create :doorkeeper_access_token, expires_in: 10.minutes,
                                                 created_at: current_time

    FactoryBot.create :doorkeeper_access_token, revoked_at: current_time - 1.year
    FactoryBot.create :doorkeeper_access_token, revoked_at: current_time - 6.months
    FactoryBot.create :doorkeeper_access_token, revoked_at: current_time - 3.months
    FactoryBot.create :doorkeeper_access_token, revoked_at: current_time - 30.days
    FactoryBot.create :doorkeeper_access_token, revoked_at: current_time - 2.weeks
    FactoryBot.create :doorkeeper_access_token, revoked_at: current_time
  end

  it 'deletes Doorkeeper grants and tokens expired or revoked more than 1 month ago' do
    expect { subject.invoke }.to  change { Doorkeeper::AccessGrant.count }.by(-7)
                             .and change { Doorkeeper::AccessToken.count }.by(-7)
  end
end
