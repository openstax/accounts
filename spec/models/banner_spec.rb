require 'rails_helper'

RSpec.describe Banner, type: :model do
  it { should validate_presence_of :message }
  it { should validate_presence_of :expires_at }
end
