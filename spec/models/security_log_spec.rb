require 'rails_helper'

RSpec.describe SecurityLog, type: :model do
  subject(:security_log) { FactoryBot.create :security_log }

  it { should belong_to :user }
  it { should belong_to :application }

  it { should validate_presence_of :event_type }

  it 'cannot be updated' do
    expect{security_log.save}.to raise_error ActiveRecord::ReadOnlyRecord
    expect{security_log.save!}.to raise_error ActiveRecord::ReadOnlyRecord
    expect{security_log.update_attribute :event_type, :admin_created}.to(
      raise_error ActiveRecord::ReadOnlyRecord
    )
    expect{security_log.update event_type: :admin_created}.to(
      raise_error ActiveRecord::ReadOnlyRecord
    )
  end

  it 'cannot be destroyed' do
    expect{security_log.destroy}.to raise_error ActiveRecord::ReadOnlyRecord
  end
end
