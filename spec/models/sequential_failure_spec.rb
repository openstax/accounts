require 'rails_helper'

RSpec.describe SequentialFailure, type: :model do
  it { should validate_presence_of(:length) }
  it { should validate_presence_of(:reference) }
  subject { SequentialFailure.confirm_by_pin.new }

  it "validates uniqueness of reference scoped to kind" do
    # Have to create a record in the db so make this test pass with `scoped_to`
    # https://github.com/thoughtbot/shoulda-matchers/issues/336
    SequentialFailure.confirm_by_pin.create!(reference: 'blah', length: 3)
    should validate_uniqueness_of(:reference).scoped_to(:kind)
  end

  it "resets" do
    sf = SequentialFailure.confirm_by_pin.create!(reference: 'blah', length: 3)
    sf.reset!
    expect(sf.reload.length).to eq 0
  end

  it "increments" do
    sf = SequentialFailure.confirm_by_pin.create!(reference: 'blah', length: 3)
    sf.increment!
    expect(sf.reload.length).to eq 4
  end

  it "returns attempts remaining" do
    sf = SequentialFailure.confirm_by_pin.create!(reference: 'blah', length: 3)
    sf.num_failures_allowed = 4
    expect(sf.attempts_remaining).to eq 1
  end

  it "returns attempts_remaining?" do
    sf = SequentialFailure.confirm_by_pin.create!(reference: 'blah', length: 3)
    sf.num_failures_allowed = 4
    expect(sf.attempts_remaining?).to be_truthy
    sf.num_failures_allowed = 3
    expect(sf.attempts_remaining?).to be_falsy
  end

end
