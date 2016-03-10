require 'rails_helper'
require 'accept_all_terms'

describe AcceptAllTerms do
  let!(:users) { (1..15).collect { |i| FactoryGirl.create(:user) } }

  it 'accept all fine print contracts for users' do
    expect {
      AcceptAllTerms.new.run
    }.to change(FinePrint::Signature, :count).by(User.count * FinePrint::Contract.count)
  end
end
