require 'date'
require 'date_time'

describe DateTime do
    it 'get correct beginning of rice fiscal year' do
        allow(DateTime).to receive(:now).and_return(Date.parse("2019-09-28"))
        year1 = DateTime.beginning_of_rice_fiscal_year
        allow(DateTime).to receive(:now).and_return(Date.parse("2020-01-01"))
        year2 = DateTime.beginning_of_rice_fiscal_year
        allow(DateTime).to receive(:now).and_return(Date.parse("2019-03-14"))
        year3 = DateTime.beginning_of_rice_fiscal_year
        expect(year1 == year2).to eq true 
        expect(year1 == year3).to eq false
    end
end