require 'rails_helper'

feature 'User claims an unclaimed account' do

  background { load 'db/seeds.rb' }
  let!(:app)   { create_default_application }
  let(:user_email) { 'unclaimeduser@example.com' }
  let(:user_options) {
    {
      email: user_email,
      application: app,
      username: 'therulerofallthings',
      first_name: Faker::Name.first_name,
      last_name: Faker::Name.last_name,
      already_verified: false
    }
  }

  def visit_invite_url
    delivery = ActionMailer::Base.deliveries.last
    match = delivery.body.encoded.match(/(confirm\/unclaimed\?code=\w+)/)
    expect(match).to_not be_nil
    visit match.captures.first
  end
end
