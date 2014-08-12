require 'spec_helper'

describe ApplicationGroup do
  
  context 'validation' do
    it 'requires application and group' do
      application_group = FactoryGirl.build :application_group
      application = application_group.application
      group = application_group.group

      expect(application_group).to be_valid
      application_group.application = nil
      expect(application_group).not_to be_valid
      expect(application_group.errors.messages[:application]).to eq(["can't be blank"])

      application_group.application = application

      expect(application_group).to be_valid
      application_group.group = nil
      expect(application_group).not_to be_valid
      expect(application_group.errors.messages[:group]).to eq(["can't be blank"])
    end

    it 'cannot have the same application and group' do
      application_group = FactoryGirl.create :application_group
      application_group2 = FactoryGirl.build :application_group,
                            application: application_group.application
      expect(application_group2).to be_valid
      application_group2.group = application_group.group
      expect(application_group2).not_to be_valid
      expect(application_group2.errors.messages[:group_id]).to eq(["has already been taken"])
    end
  end

end
