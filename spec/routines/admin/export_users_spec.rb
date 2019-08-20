require 'rails_helper'

RSpec.describe Admin::ExportUsers, type: :routine do

  before(:all) do
    @user_1 = FactoryBot.create :user_with_emails
    @user_2 = FactoryBot.create :user, first_name: 'Mary',
                                        last_name: 'Mighty',
                                        username: 'mary'
    @user_3 = FactoryBot.create :user, first_name: 'John',
                                        last_name: 'Stead',
                                        username: 'jstead'

    @identity_1 = FactoryBot.create :identity, user: @user_1
    @authentication_1 = FactoryBot.create :authentication, user: @user_1,
                                                            provider: 'identity',
                                                            uid: @identity_1.id

    @identity_2 = FactoryBot.create :identity, user: @user_2
    @authentication_2 = FactoryBot.create :authentication, user: @user_2,
                                                            provider: 'identity',
                                                            uid: @identity_2.id

    @billy_users = (0..45).to_a.map do |ii|
      FactoryBot.create :user,
                         first_name: "Billy#{ii.to_s.rjust(2, '0')}",
                         last_name: "Bob_#{(45-ii).to_s.rjust(2,'0')}",
                         username: "billy_#{ii.to_s.rjust(2, '0')}"
    end

    @filename = 'tmp/test.json'
  end

  after(:all)    { File.delete(@filename) if File.exist?(@filename) }

  it 'can export users' do
    users = [ @user_1, @user_2, @user_3 ]
    expect { described_class.call(users: users, filename: @filename) }.not_to raise_error
    array = JSON.parse File.read(@filename)
    array.each_with_index do |user_hash, index|
      user = users[index]

      user.attributes.except('id').each do |attribute, value|
        expect(user_hash[attribute]).to eq JSON.load(value.to_json)
      end

      user.identity.attributes.except('id', 'user_id').each do |attribute, value|
        expect(user_hash['identity'][attribute]).to eq JSON.load(value.to_json)
      end unless user.identity.nil?

      user.authentications.each_with_index do |authentication, a_index|
        authentication.attributes.except('id', 'user_id').each do |attribute, value|
          next if authentication.provider == 'identity' && attribute == 'uid'

          expect(user_hash['authentications'][a_index][attribute]).to eq JSON.load(value.to_json)
        end
      end

      user.contact_infos.each_with_index do |contact_info, c_index|
        contact_info.attributes.except('id', 'user_id').each do |attribute, value|
          expect(user_hash['contact_infos'][c_index][attribute]).to eq JSON.load(value.to_json)
        end
      end
    end
  end

end
