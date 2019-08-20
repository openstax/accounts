require 'rails_helper'

RSpec.describe Admin::ReportsController, type: :controller do
  let(:admin) { FactoryBot.create :user, :admin, :terms_agreed }

  before(:each) do
    controller.sign_in! admin
  end

  it 'gets number of users' do
    expect(User.count).to (eq 1)
  end

end
