require 'rails_helper'
require 'vcr_helper'

RSpec.describe UpdateBooksFromSalesforce, type: :routine, vcr: VCR_OPTS do
  before(:all) do
    VCR.use_cassette('UpdateBookSalesforceInfo/sf_setup', VCR_OPTS) do
      @proxy = SalesforceProxy.new
      @proxy.setup_cassette
    end
  end

  it "expects books to be created" do
    described_class.call
    expect(Book.count).to_not eq 0
  end
end
