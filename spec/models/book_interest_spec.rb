require 'rails_helper'

RSpec.describe BookInterest do
  it 'parses a ;-separated string, trimming, dropping blanks and duplicates' do
    expect(described_class.parse(' Biology; ;College Physics;Biology ')).to eq(['Biology', 'College Physics'])
  end

  it 'parses nil, and arrays of strings' do
    expect(described_class.parse(nil)).to eq([])
    expect(described_class.parse(['Biology;Astronomy', 'Biology'])).to eq(%w[Biology Astronomy])
  end

  it 'applies (current - remove) + add, with remove winning' do
    expect(described_class.apply('A;B', add: %w[C B], remove: %w[A C])).to eq(%w[B])
  end

  it 'keeps bracketed values whole' do
    expect(described_class.parse('Calculus Volume 1 [Spanish];Biology')).to eq(['Calculus Volume 1 [Spanish]', 'Biology'])
  end
end
