require 'rails_helper'

describe Person do

  context 'deletion' do
    before :each do
      @person = FactoryGirl.create :person
      @user1 = FactoryGirl.create :temp_user, person: @person
      @user2 = FactoryGirl.create :temp_user, person: @person
    end

    it 'does not delete the person when deleting a user' do
      @user1.destroy

      expect(Person.exists? @person.id).to be_truthy
      expect(User.exists? @user1.id).to be_falsey
      expect(User.exists? @user2.id).to be_truthy
    end

    it 'does delete all the users when deleting a person' do
      @person.destroy

      expect(Person.exists? @person.id).to be_falsey
      expect(User.exists? @user1.id).to be_falsey
      expect(User.exists? @user2.id).to be_falsey
    end
  end

end
