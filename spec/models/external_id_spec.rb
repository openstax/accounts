require 'rails_helper'

describe ExternalId, type: :model do
  subject { FactoryBot.create :external_id }

  it { is_expected.to belong_to(:user) }
  it { is_expected.to validate_presence_of(:external_id) }
  it { is_expected.to validate_uniqueness_of(:external_id) }
end
