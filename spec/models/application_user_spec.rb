require 'rails_helper'

describe ApplicationUser do

  context 'validation' do
    it 'requires default_contact_info to belong to the user' do
      application_user = FactoryBot.create :application_user
      expect(application_user).to be_valid
      contact_info = FactoryBot.create :email_address
      application_user.default_contact_info = contact_info
      expect(application_user).not_to be_valid
      expect(application_user.errors.messages[:default_contact_info]).to eq(['must belong to the given user.'])
      application_user.user = contact_info.user
      expect(application_user).to be_valid
    end

    it 'requires application and user' do
      application_user = FactoryBot.build :application_user
      application = application_user.application
      user = application_user.user

      expect(application_user).to be_valid
      application_user.application = nil
      expect(application_user).not_to be_valid
      expect(application_user).to have_error(:application, :blank)

      application_user.application = application

      expect(application_user).to be_valid
      application_user.user = nil
      expect(application_user).not_to be_valid
      expect(application_user).to have_error(:user, :blank)
    end

    it 'cannot have the same application and user' do
      application_user = FactoryBot.create :application_user
      application_user2 = FactoryBot.build :application_user,
                            application: application_user.application
      expect(application_user2).to be_valid
      application_user2.user = application_user.user
      expect(application_user2).not_to be_valid
      expect(application_user2).to have_error(:user_id, :taken)
    end
  end

end
