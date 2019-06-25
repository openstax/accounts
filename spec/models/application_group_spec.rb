require 'rails_helper'

describe ApplicationGroup do

  context 'validation' do
    it 'requires application and group' do
      application_group = FactoryBot.build :application_group
      application = application_group.application
      group = application_group.group

      expect(application_group).to be_valid
      application_group.application = nil
      expect(application_group).not_to be_valid
      expect(application_group).to have_error(:application, :blank)

      application_group.application = application

      expect(application_group).to be_valid
      application_group.group = nil
      expect(application_group).not_to be_valid
      expect(application_group).to have_error(:group, :blank)
    end

    it 'cannot have the same application and group' do
      application_group = FactoryBot.create :application_group
      application_group2 = FactoryBot.build :application_group,
                            application: application_group.application
      expect(application_group2).to be_valid
      application_group2.group = application_group.group
      expect(application_group2).not_to be_valid
      expect(application_group2).to have_error(:group_id, :taken)
    end
  end

end
