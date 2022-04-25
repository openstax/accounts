require 'rails_helper'

describe Admin::SecurityLogsController, type: :controller do
  let(:no_results) do { outputs: {items: SecurityLog.none} } end
  let(:admin) { FactoryBot.create :user, :admin, :terms_agreed }

  before(:each) do
    controller.sign_in! admin
  end

  context 'GET #show' do
    it 'passes an empty hash to Admin::SearchSecurityLog if there is no search query' do
      expect(Admin::SearchSecurityLog).to receive(:call).with({}).and_return(no_results)

      get(:show)
    end

    it 'passes search parameters to Admin::SearchSecurityLog' do
      expect(Admin::SearchSecurityLog).to receive(:call).with(query: 'test').and_return(no_results)

      get(:show, params: { search: {query: 'test'} })
    end
  end
end
