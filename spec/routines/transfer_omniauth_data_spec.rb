require 'rails_helper'

RSpec.describe TransferOmniauthData, type: :routine do

  let(:user)      { FactoryBot.build :user }
  let(:auth_data) { OmniauthData.new auth_hash }

  subject         { described_class.call(auth_data, user) }

  context 'when auth provider is identity' do
    let(:auth_hash) { OmniAuth::AuthHash.new provider: 'identity', uid: '12345' }

    it 'raises error because we should not get here' do
      expect { subject }.to raise_error(Unexpected)
    end
  end

  context 'when the user has non-blank names' do
    let(:auth_hash) do
      OmniAuth::AuthHash.new(
        provider: 'google_oauth2', uid: '12345678', info: { first_name: 'User', last_name: 'One' }
      )
    end

    it 'persists the user but does not update their names' do
      expect { subject }.to  change     { user.new_record? }.from(true).to(false)
                        .and not_change { user.first_name  }
                        .and not_change { user.last_name   }
    end
  end

  context 'when the user has blank names' do
    before do
      user.first_name = ''
      user.last_name = ''
    end

    context 'when the auth provider is facebook' do
      let(:auth_hash) do
        OmniAuth::AuthHash.new(provider: 'facebook', uid: '1234567890').tap do |hash|
          hash.extra = {
            raw_info: {
              email: 'user@example.com',
              first_name: 'User',
              last_name: 'One',
              gender: 'female',
              id: '1234567890',
              languages: [{id: '106059522759137', name: 'English'}],
              link: 'https://www.facebook/user.one',
              locale: 'en_US',
              location: {id: '116045151742300', name: 'Munich, Germany'},
              name: 'User N. One',
              timezone: 1,
              updated_time: '2013-07-28T18:22:46+0000',
              username: 'user1',
              verified: 'true',
            },
          }

          hash.info = {
            email: 'user@example.com',
            first_name: 'User',
            image: 'http://graph.facebook.com/1234567890/picture?type=square',
            last_name: 'One',
            location: 'Munich, Germany',
            name: 'User N. One',
            nickname: 'user1',
            urls: {Facebook: 'https://www.facebook.com/user.one'},
            verified: true
          }
        end
      end

      it 'stores user information' do
        expect{ subject }.to  change { user.new_record?          }.from(true).to(false)
                         .and change { user.first_name           }.to('User')
                         .and change { user.last_name            }.to('One')
                         .and change { user.contact_infos.length }.from(0).to(1)

        expect(user.contact_infos.first.type).to eq 'EmailAddress'
        expect(user.contact_infos.first.value).to eq 'user@example.com'
        expect(user.contact_infos.first.verified).to eq true
      end

      context 'when the user already has the returned email address' do
        before do
          user.save!

          FactoryBot.create :email_address, user: user, value: 'user@example.com'
        end

        context 'when the existing email address is unverified' do
          it 'stores user information and verifies the email address' do
            expect{ subject }.to  change     { user.first_name           }.to('User')
                             .and change     { user.last_name            }.to('One')
                             .and not_change { user.contact_infos.length }
                             .and not_change { user.contact_infos.first.type }
                             .and not_change { user.contact_infos.first.value }
                             .and(change     do
                               user.contact_infos.first.verified
                             end.from(false).to(true))
          end
        end

        context 'when the existing email address is verified' do
          before { user.contact_infos.first.update_attribute :verified, true } # rubocop:disable Rails/SkipsModelValidations

          it 'stores user information' do
            expect{ subject }.to  change     { user.first_name           }.to('User')
                             .and change     { user.last_name            }.to('One')
                             .and not_change { user.contact_infos.length }
                             .and not_change { user.contact_infos.first.type }
                             .and not_change { user.contact_infos.first.value }
                             .and not_change { user.contact_infos.first.verified }
          end
        end
      end
    end

    context 'when auth provider is google' do
      let(:auth_hash) do
        OmniAuth::AuthHash.new(provider: 'google_oauth2', uid: '12345678901234567890').tap do |hash|
          hash.extra = {
            id_token: 'SoMeLoNgRaNdOmStRiNg',
            raw_info: {
              email: 'user@example.com',
              family_name: 'One',
              gender: 'female',
              given_name: 'User',
              hd: 'example.com',
              id: '1234567890',
              link: 'https://plus.google.com/1234567890',
              locale: 'en',
              name: 'User N. One',
              picture: 'https://lh5.googleusercontent.com/xxxxxx/yyyyy/photo.jpg',
              verified_email: true,
            }
          }

          hash.info = {
            email: 'user@example.com',
            first_name: 'User',
            image: 'https://lh5.googleusercontent.com/xxxxxx/yyyyy/photo.jpg',
            last_name: 'One',
            name: 'User N. One',
            urls: { Google: 'https://plus.google.com/1234567890' },
          }
        end
      end

      it 'stores user information' do
        expect{ subject }.to  change { user.new_record?          }.from(true).to(false)
                         .and change { user.first_name           }.to('User')
                         .and change { user.last_name            }.to('One')
                         .and change { user.contact_infos.length }.from(0).to(1)

        expect(user.contact_infos.first.type).to eq 'EmailAddress'
        expect(user.contact_infos.first.value).to eq 'user@example.com'
        expect(user.contact_infos.first.verified).to eq true
      end

      context 'when the user already has the returned email address' do
        before do
          user.save!

          FactoryBot.create :email_address, user: user, value: 'user@example.com'
        end

        context 'when the existing email address is unverified' do
          it 'stores user information and verifies the email address' do
            expect{ subject }.to  change     { user.first_name           }.to('User')
                             .and change     { user.last_name            }.to('One')
                             .and not_change { user.contact_infos.length }
                             .and not_change { user.contact_infos.first.type }
                             .and not_change { user.contact_infos.first.value }
                             .and(change     do
                               user.contact_infos.first.verified
                             end.from(false).to(true))
          end
        end

        context 'when the existing email address is verified' do
          before { user.contact_infos.first.update_attribute :verified, true } # rubocop:disable Rails/SkipsModelValidations

          it 'stores user information' do
            expect{ subject }.to  change     { user.first_name           }.to('User')
                             .and change     { user.last_name            }.to('One')
                             .and not_change { user.contact_infos.length }
                             .and not_change { user.contact_infos.first.type }
                             .and not_change { user.contact_infos.first.value }
                             .and not_change { user.contact_infos.first.verified }
          end
        end
      end
    end
  end

end
