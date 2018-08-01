require 'rails_helper'

RSpec.describe Banner, type: :model do
  it { should validate_presence_of :message }
  it { should validate_presence_of :expires_at }

  describe "#active_until" do
    it "nicely formats expires_at as string" do
      subject.expires_at = DateTime.new(2024, 8, 18, 3, 33)
      expected = '08/18/2024 03:33AM'
      expect(subject.active_until).to eq(expected)
    end
  end

  describe "timezone" do
    it "saves UTC in the database" do
      central_time = 'Wed, 01 Aug 2018 17:11:52 -0500'
      utc_time = 'Wed, 01 Aug 2018 22:11:52 UTC +00:00'
      banner = Banner.create(message: 'wtvr', expires_at: central_time)
      expect(Banner.pluck(:expires_at)).to eq([central_time])
    end
  end
end
