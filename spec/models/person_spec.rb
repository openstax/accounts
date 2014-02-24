require 'spec_helper'

describe Person do

  context 'deletion' do
    before :each do
      @person = FactoryGirl.create :person
      @user1 = FactoryGirl.create :user, person: @person
      @user2 = FactoryGirl.create :user, person: @person
    end

    it 'does not delete the person when deleting a user' do
      @user1.destroy

      expect(Person.exists? @person.id).to be_true
      expect(User.exists? @user1.id).to be_false
      expect(User.exists? @user2.id).to be_true
    end

    it 'does delete all the users when deleting a person' do
      @person.destroy

      expect(Person.exists? @person.id).to be_false
      expect(User.exists? @user1.id).to be_false
      expect(User.exists? @user2.id).to be_false
    end
  end

end
