require 'rails_helper'

describe Admin::BannersController, type: :controller do
  let(:admin) { FactoryGirl.create :user, :admin, :terms_agreed }

  before(:each) do
    controller.sign_in! admin
  end

  it 'finds active (unexpired) banners' do
    2.times {
      Banner.create!(expires_at: 8.hours.from_now, message: 'This is a banner.')
    }
    Banner.create!(expires_at: 1.second.ago, message: 'This is an inactive/expired banner.')
    get :index
    expect(assigns(:banners).count).to eq 2
  end
end
