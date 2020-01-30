require 'date'
require 'date_time'

describe DateTime do
  it 'get correct beginning of rice fiscal year' do
    allow(DateTime).to receive(:now).and_return(Date.parse("2019-09-28"))
    expect(DateTime.beginning_of_rice_fiscal_year).to eq DateTime.parse("2019-07-01")
    allow(DateTime).to receive(:now).and_return(Date.parse("2020-01-01"))
    expect(DateTime.beginning_of_rice_fiscal_year).to eq DateTime.parse("2019-07-01")
    allow(DateTime).to receive(:now).and_return(Date.parse("2019-03-14"))
    expect(DateTime.beginning_of_rice_fiscal_year).to eq DateTime.parse("2018-07-01")
  end
end