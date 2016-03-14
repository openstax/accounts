require 'rails_helper'

describe Dev::DestroyUsers do

  it "works" do
    FactoryGirl.create(:temp_user)
    FactoryGirl.create(:user)

    expect{Dev::DestroyUsers.call(User.all)}.to change(User, :count).by(-2)
  end

end
