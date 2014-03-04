require 'spec_helper'

describe DoController do

  describe "GET 'confirm_email'" do
    render_views

    before :each do
      @email = EmailAddress.create(confirmation_code: '1234', verified: false, value: 'user@example.com')
    end

    it "returns error if no code given" do
      get 'confirm_email'
      expect(response.code).to eq('400')
      expect(response.body).to include("Sorry, we couldn't verify an email using the confirmation code you provided.")
      expect(EmailAddress.find_by_value(@email.value).verified).to be_false
    end

    it "returns error if code doesn't match" do
      get 'confirm_email', :code => 'abcd'
      expect(response.code).to eq('400')
      expect(response.body).to include("Sorry, we couldn't verify an email using the confirmation code you provided.")
      expect(EmailAddress.find_by_value(@email.value).verified).to be_false
    end

    it "returns success if code matches" do
      get 'confirm_email', :code => @email.confirmation_code
      expect(response).to be_success
      expect(response.body).to include('Success! Thanks for adding your email address.')
      expect(EmailAddress.find_by_value(@email.value).verified).to be_true
    end
  end

  context 'reset_password' do
    render_views

    let!(:user) { FactoryGirl.create :user, username: 'user_one' }
    let!(:identity) {
      i = FactoryGirl.create :identity, user: user, password: 'password'
      i.generate_reset_code
      i
    }

    describe 'GET' do
      it 'returns error if no code given' do
        get 'reset_password'
        expect(response.code).to eq('400')
        expect(response.body).to include('Reset password link is invalid')
        expect(response.body).not_to include('Set Password')
      end

      it "returns error if code doesn't match" do
        get 'reset_password', code: 'abcd'
        expect(response.code).to eq('400')
        expect(response.body).to include('Reset password link is invalid')
        expect(response.body).not_to include('Set Password')
      end

      it 'returns error if code has expired' do
        one_year_later = DateTime.now + 1.year
        DateTime.stub(:now).and_return(one_year_later)
        get 'reset_password', code: identity.reset_code
        DateTime.unstub(:now)

        expect(response.code).to eq('400')
        expect(response.body).to include('Reset password link has expired')
        expect(response.body).not_to include('Set Password')
      end

      it 'shows reset password form if code matches' do
        get 'reset_password', code: identity.reset_code
        expect(response).to be_successful
        expect(response.body).not_to include('Reset password link is invalid')
        expect(response.body).to include('Set Password')
      end
    end

    describe 'POST' do
      it 'returns error if no code given' do
        post 'reset_password'
        expect(response.code).to eq('400')
        expect(response.body).to include('Reset password link is invalid')
        expect(response.body).not_to include('Set Password')
        identity.reload
        expect(identity.authenticate('password')).to be_true
      end

      it "returns error if code doesn't match" do
        post 'reset_password', code: 'abcd'
        expect(response.code).to eq('400')
        expect(response.body).to include('Reset password link is invalid')
        expect(response.body).not_to include('Set Password')
        identity.reload
        expect(identity.authenticate('password')).to be_true
      end

      it 'returns error if password is empty' do
        post('reset_password', code: identity.reset_code,
             :'reset_password[password]' => '',
             :'reset_password[password_confirmation]' => '')
        expect(response.code).to eq('400')
        expect(response.body).not_to include('Reset password link is invalid')
        expect(response.body).to include("Password can't be blank")
        expect(response.body).to include('Set Password')
        identity.reload
        expect(identity.authenticate('password')).to be_true
      end

      it 'returns error if password is too short' do
        post('reset_password', code: identity.reset_code,
             :'reset_password[password]' => 'pass',
             :'reset_password[password_confirmation]' => 'pass')
        expect(response.code).to eq('400')
        expect(response.body).not_to include('Reset password link is invalid')
        expect(response.body).to include('Password is too short')
        expect(response.body).to include('Set Password')
        identity.reload
        expect(identity.authenticate('password')).to be_true
      end

      it "returns error if password and password confirmation don't match" do
        post('reset_password', code: identity.reset_code,
             reset_password: { password: 'password', password_confirmation: 'passwordd'})
        expect(response.code).to eq('400')
        expect(response.body).not_to include('Reset password link is invalid')
        expect(response.body).to include("Password doesn&#x27;t match confirmation")
        expect(response.body).to include('Set Password')
        identity.reload
        expect(identity.authenticate('password')).to be_true
      end

      it 'changes password if everything validates' do
        post('reset_password', code: identity.reset_code,
             reset_password: { password: 'password!', password_confirmation: 'password!'})
        expect(response).to be_successful
        expect(response.body).not_to include('Reset password link is invalid')
        expect(response.body).to include('Your password has been reset successfully!')
        expect(response.body).not_to include('Set Password')
        identity.reload
        expect(identity.authenticate('password')).to be_false
        expect(identity.authenticate('password!')).to be_true
      end

      it 'redirects to return_to if it is set' do
        DoController.any_instance.stub(:session).and_return(
          {return_to: 'http://www.example.com/'})
        post('reset_password', code: identity.reset_code,
             reset_password: { password: 'password!', password_confirmation: 'password!'})

        expect(response.code).to eq('302')
        expect(response.header['Location']).to eq('http://www.example.com/')

        identity.reload
        expect(identity.authenticate('password')).to be_false
        expect(identity.authenticate('password!')).to be_true
      end
    end
  end

end
