require 'rails_helper'

RSpec.describe SecurityLog, type: :model do
  it { is_expected.to belong_to :user }
  it { is_expected.to belong_to :application }

  it { is_expected.to validate_presence_of :remote_ip }
  it { is_expected.to validate_presence_of :event_type }
  it { is_expected.to validate_presence_of :event_data }
end
