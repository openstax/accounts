require 'spec_helper'

describe Dev::DestroyUsers do

  it "works" do
    FactoryGirl.create(:user)
    FactoryGirl.create(:user_with_person)

    expect{Dev::DestroyUsers.call(User.all)}.to change(User, :count).by(-2)
  end

end