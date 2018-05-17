require 'rails_helper'

RSpec.describe Admin::ImportUsers, type: :routine do

  let(:filename) { 'spec/fixtures/users.json' }

  it 'can import users' do
    expect { described_class.call(filename: filename) }.to change  { User.count }.by(3)
                                                       .and change { Identity.count }.by(2)
                                                       .and change { Authentication.count }.by(2)
                                                       .and change { ContactInfo.count }.by(2)
  end

end
