require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do

  let!(:user)               { FactoryBot.create :user, :terms_agreed }
  let!(:app_token)          { FactoryBot.create :doorkeeper_access_token, resource_owner_id: nil }
  let!(:application)        { app_token.application }
  let!(:user_token)         { FactoryBot.create :doorkeeper_access_token,
                                                 application: nil,
                                                 resource_owner_id: user.id }
  let!(:app_and_user_token) { FactoryBot.create :doorkeeper_access_token,
                                                 application: application,
                                                 resource_owner_id: user.id }

  let!(:anonymous_api_user)    { OpenStax::Api::ApiUser.new(nil, -> { nil }) }
  let!(:user_api_user)         { OpenStax::Api::ApiUser.new(user_token, -> { nil }) }
  let!(:app_api_user)          { OpenStax::Api::ApiUser.new(app_token, -> { nil }) }
  let!(:app_and_user_api_user) { OpenStax::Api::ApiUser.new(app_and_user_token, -> { nil }) }

  context 'security log' do
    context 'non-api controller' do
      context 'anonymous user' do
        it 'does not set the user or application fields' do
          expect{ controller.send :security_log, :unknown }.to change{ SecurityLog.count }.by(1)
          security_log = SecurityLog.first
          expect(security_log.user).to be_nil
          expect(security_log.application).to be_nil
        end
      end

      context 'human user' do
        before{ controller.sign_in! user }

        it 'sets the user field but not the application field' do
          expect{ controller.send :security_log, :unknown }.to change{ SecurityLog.count }.by(1)
          security_log = SecurityLog.first
          expect(security_log.user).to eq user
          expect(security_log.application).to be_nil
        end
      end
    end

    context 'api controller' do
      before{ controller.class.send :attr_accessor, :current_api_user }
      after do
        controller.class.send :undef_method, :current_api_user
        controller.class.send :undef_method, :current_api_user=
      end

      context 'anonymous user' do
        before{ controller.current_api_user = anonymous_api_user }

        it 'does not set the user or application fields' do
          expect{ controller.send :security_log, :unknown }.to change{ SecurityLog.count }.by(1)
          security_log = SecurityLog.first
          expect(security_log.user).to be_nil
          expect(security_log.application).to be_nil
        end
      end

      context 'human user (cookie)' do
        before{ controller.current_api_user = user_api_user }

        it 'sets the user field but not the application field' do
          expect{ controller.send :security_log, :unknown }.to change{ SecurityLog.count }.by(1)
          security_log = SecurityLog.first
          expect(security_log.user).to eq user
          expect(security_log.application).to be_nil
        end
      end

      context 'application (client credentials)' do
        before{ controller.current_api_user = app_api_user }

        it 'sets the application field but not the user field' do
          expect{ controller.send :security_log, :unknown }.to change{ SecurityLog.count }.by(1)
          security_log = SecurityLog.first
          expect(security_log.user).to be_nil
          expect(security_log.application).to eq application
        end
      end

      context 'application (authorization code)' do
        before{ controller.current_api_user = app_and_user_api_user }

        it 'sets both user and application fields' do
          expect{ controller.send :security_log, :unknown }.to change{ SecurityLog.count }.by(1)
          security_log = SecurityLog.first
          expect(security_log.user).to eq user
          expect(security_log.application).to eq application
        end
      end
    end
  end

end
