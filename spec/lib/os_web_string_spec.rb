require 'rails_helper'

RSpec.describe OsWebString, type: :lib do
  let(:osweb_url) { 'https://openstax.org' }

  before do
    Rails.application.secrets.openstax_url = osweb_url
  end

  example 'a passed-in string matches what we have stored in the secrets as the openstax_url' do
    expect(described_class.new(osweb_url).came_from_osweb?).to eq(true)
  end
end
