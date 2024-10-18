require 'rails_helper'

describe Banner, type: :model do
  it { should validate_presence_of :message }
  it { should validate_presence_of :expires_at }

  describe "#active_until" do
    it "nicely formats expires_at as string" do
      subject.expires_at = DateTime.new(2024, 8, 18, 3, 33)
      expected = '08/17/2024 10:33PM CDT'
      expect(subject.active_until).to eq(expected)
    end
  end
end
