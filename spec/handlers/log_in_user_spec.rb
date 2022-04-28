require 'rails_helper'

describe LogInUser, type: :handler do
  let!(:user) { create_user 'user@openstax.org' }
  let(:request) {
    # ip address needed for generating a security log
    Hashie::Mash.new(ip: Faker::Internet.ip_v4_address)
  }

  context 'when correct credentials (success)' do
    let(:params) {
      {
        login_form: { email: user.email_addresses.first.value, password: 'password' }
      }
    }

    it 'outputs the user' do
      result = described_class.handle(params: params, request: request)
      expect(result.outputs.user).to be_present
    end
  end

  context 'when incorrect credentials (failure)' do
    it 'contains errors when wrong email' do
      params = {
        login_form: { email: 'nonexistent@openstax.org', password: 'password' }
      }
      result = described_class.handle(params: params, request: request)
      expect(result.errors).to be_present
    end

    it 'contains errors when wrong password' do
      params = {
        login_form: { email: user.email_addresses.first.value, password: 'wrongpassword' }
      }
      result = described_class.handle(params: params, request: request)
      expect(result.errors).to be_present
    end

    it 'adds errors to the correct field' do
      [:email, :password].each do |field|
        params = {
          login_form: {
            email: user.email_addresses.first.value,
            password: 'password'
          }
        }

        params[:login_form].each_with_object({}) do |(key, value), hash|
          # Modify (only) the field
          key == field ? (hash[key] = value.prepend('z')) : value
        end

        result = described_class.handle(params: params, request: request)
        expect(result.errors).to have_offending_input(field)
      end
    end
  end
end
