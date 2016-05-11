require 'rails_helper'

describe Admin::SecurityLogsController, type: :controller do
  let(:no_results) { OpenStruct.new(outputs: OpenStruct.new(items: SecurityLog.where('1=0'))) }

  context 'GET #show' do
    it 'passes an empty hash to Admin::SearchSecurityLog if there is no search query' do
      expect(Admin::SearchSecurityLog).to receive(:call).with({}).and_return(no_results)

      get :show
    end

    it 'passes search parameters to Admin::SearchSecurityLog' do
      expect(Admin::SearchSecurityLog).to receive(:call).with(query: 'test').and_return(no_results)

      get :show, search: {query: 'test'}
    end
  end
end
