require 'rails_helper'

describe Admin::BannersController, type: :controller do
  let(:admin) { FactoryBot.create :user, :admin, :terms_agreed }

  before(:each) do
    controller.sign_in! admin
  end

  it 'finds active (unexpired) banners' do
    2.times { Banner.create!(expires_at: 8.hours.from_now, message: 'banner') }
    expired_banner = Banner.create(expires_at: 8.hours.from_now, message: 'expired banner')
    expired_banner.update_attribute(:expires_at, 1.second.ago)

    get :index
    expect(assigns(:banners).count).to eq 2
  end
end
