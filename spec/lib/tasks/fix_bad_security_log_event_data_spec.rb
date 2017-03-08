require 'rails_helper'

RSpec.describe "fix_bad_security_log_event_data" do
  include_context "rake"

  before(:each) do
    @goods = {}
    @bads = {}

    @goods[:cannot_find_user], @bads[:cannot_find_user] = good_and_bad(reason: :cannot_find_user)
    @goods[:bad_password], @bads[:bad_password] = good_and_bad(reason: :bad_password)
    @goods[:multiple_users], @bads[:multiple_users] = good_and_bad(reason: :multiple_users)
    @goods[:too_many_login_attempts], @bads[:too_many_login_attempts] = good_and_bad(reason: :too_many_login_attempts)
  end

  it "works" do
    # Check that the goods are good and the bads are bad in the way we see on production
    @goods.each { |_, good| expect{good.reload}.not_to raise_error }
    @bads.each  { |_, bad|  expect{bad.reload}.to raise_error(JSON::ParserError) }

    call

    # Check that goods are unchanged and still load
    @goods.each do |reason, good|
      expect{good.reload}.not_to raise_error
      expect(good.event_data).to eq({ "reason" => reason.to_s })
    end

    # Check that bads load now and have the right event_data
    @bads.each do |reason, bad|
      expect{bad.reload}.not_to raise_error
      expect(bad.event_data).to eq({ "reason" => reason.to_s })
    end
  end


  def good_and_bad(reason:)
    good = FactoryGirl.create :security_log, event_data: { reason: reason.to_s }

    bad = FactoryGirl.create :security_log
    ActiveRecord::Base.connection.execute(
      "update security_logs set event_data='---\n:reason: #{reason}\n' where id=#{bad.id}"
    )

    [good, bad]
  end

end
