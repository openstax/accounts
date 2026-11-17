require 'rails_helper'

describe SequentialFailure, type: :model do
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

  it "creates the row on the first increment" do
    sf = SequentialFailure.confirm_by_pin.new(reference: 'fresh')
    sf.increment!
    expect(sf).to be_persisted
    expect(SequentialFailure.confirm_by_pin.find_by!(reference: 'fresh').length).to eq 1
  end

  it "counts against the stored row, not a stale in-memory copy" do
    sf = SequentialFailure.confirm_by_pin.create!(reference: 'blah', length: 3)
    stale = SequentialFailure.find(sf.id)
    sf.increment!
    stale.increment!
    expect(stale.length).to eq 5
    expect(sf.reload.length).to eq 5
  end

  it "does not collide when two unsaved copies of a new row both increment" do
    a = SequentialFailure.confirm_by_pin.new(reference: 'race')
    b = SequentialFailure.confirm_by_pin.find_or_initialize_by(reference: 'race')
    a.increment!
    expect { b.increment! }.not_to raise_error
    expect(a.reload.length).to eq 2
  end

  it "can be reset after an increment" do
    sf = SequentialFailure.confirm_by_pin.new(reference: 'fresh')
    sf.increment!
    expect { sf.reset! }.not_to change(SequentialFailure, :count)
    expect(sf.reload.length).to eq 0
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
