require 'spec_helper'

describe ContactInfo do

  context 'validation' do
    it 'does not accept empty value' do
      info = ContactInfo.create
      expect(info).not_to be_valid
      expect(info.errors.messages[:value]).to eq(["can't be blank"])
    end
  end

end
