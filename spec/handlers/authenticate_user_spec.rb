require 'rails_helper'

describe AuthenticateUser, type: :handler do
  let!(:user) { create_newflow_user 'user@openstax.org', 'password', confirmation_code: '01234' }

  before do
    # Emails aren't immediately verified on sign up
    email.update_attributes(verified: true)
  end

  context 'when correct credentials (success)' do
    it 'outputs the user' do
      params = {
        login_form: { email: user.email_addresses.first.value, password: identity.password }
      }
      result = described_class.handle(params: params)
      expect(result.outputs.user).to be_present
    end
  end

  context 'when incorrect credentials (failure)' do
    it 'contains errors when wrong email' do
      params = {
        login_form: { email: 'nonexistent@openstax.org', password: identity.password }
      }
      result = described_class.handle(params: params)
      expect(result.errors).to be_present
    end

    it 'contains errors when wrong password' do
      params = {
        login_form: { email: user.email_addresses.first.value, password: 'incorrect_one' }
      }
      result = described_class.handle(params: params)
      expect(result.errors).to be_present
    end

    it 'adds errors to the correct field' do
      [:email, :password].each do |field|
        params = {
          login_form: {
            email: user.email_addresses.first.value,
            password: identity.password
          }
        }

        params[:login_form].each_with_object({}) do |(key, value), hash|
          key == field ? (hash[key] = value.prepend('z')) : value
        end

        result = described_class.handle(params: params)
        expect(result.errors).to have_offending_input(field)
      end
    end
  end
end
