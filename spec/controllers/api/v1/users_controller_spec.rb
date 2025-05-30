require 'rails_helper'

describe Api::V1::UsersController, type: :controller, api: true, version: :v1 do
  let!(:untrusted_application) { FactoryBot.create :doorkeeper_application }
  let!(:trusted_application)   { FactoryBot.create :doorkeeper_application, :trusted }

  let!(:untrusted_application_token) do
    FactoryBot.create :doorkeeper_access_token, application: untrusted_application,
                                                resource_owner_id: nil
  end
  let!(:trusted_application_token) do
    FactoryBot.create :doorkeeper_access_token, application: trusted_application,
                                                resource_owner_id: nil
  end

  let!(:user_1)          { FactoryBot.create :user, :terms_agreed, last_name: 'Doe' }
  let!(:user_2)          do
    FactoryBot.create :user_with_emails, :terms_agreed,
                       first_name: 'Bob', last_name: 'Michaels', salesforce_contact_id: "somesfid"
  end
  let!(:unclaimed_user)  do
    FactoryBot.create :user_with_emails, state: 'unclaimed', last_name: 'Unclaimed'
  end
  let!(:admin_user)      do
    FactoryBot.create :user, :terms_agreed, :admin, first_name: 'Joe', last_name: 'Admin'
  end
  let!(:billy_users) do
    (0..45).to_a.map do |ii|
      FactoryBot.create :user,
                         first_name: "Billy#{ii.to_s.rjust(2, '0')}",
                         last_name: "Fred_#{(45-ii).to_s.rjust(2,'0')}",
                         username: "billy_#{ii.to_s.rjust(2, '0')}"
    end
  end
  let!(:bob_brown) do
    FactoryBot.create :user, first_name: "Bob", last_name: "Brown", username: "foo_bb"
  end
  let!(:bob_jones) do
    FactoryBot.create :user, first_name: "Bob", last_name: "Jones", username: "foo_bj"
  end
  let!(:tim_jones) do
    FactoryBot.create :user, first_name: "Tim", last_name: "Jones", username: "foo_tj"
  end

  let!(:user_1_token)    do
    FactoryBot.create :doorkeeper_access_token, application: untrusted_application,
                                                resource_owner_id: user_1.id
  end
  let!(:user_2_token)    do
    FactoryBot.create :doorkeeper_access_token, application: untrusted_application,
                                                resource_owner_id: user_2.id
  end
  let!(:admin_token) do
    FactoryBot.create :doorkeeper_access_token, application: untrusted_application,
                                                resource_owner_id: admin_user.id
  end

  let(:is_not_gdpr_location) { nil }

  context "index" do
    it "does not explode when called without params" do
      api_get :index, trusted_application_token
      expect(response.code).to eq('200')
      expect(response.body_as_hash).to match({ total_count: User.count, items: [] })
    end

    it "returns a single result well" do
      api_get :index, trusted_application_token, params: { q: 'first_name:bob last_name:Michaels' }
      expect(response.code).to eq('200')

      expected_response = {
        total_count: 1,
        items: [ user_matcher(user_2, include_private_data: true) ]
      }

      expect(response.body_as_hash).to match(expected_response)
    end

    it "returns a single result well with private data" do
      trusted_application.update_attribute(:can_access_private_user_data, true)
      api_get :index, trusted_application_token, params: { q: 'first_name:bob last_name:Michaels' }
      expect(response.code).to eq('200')

      expected_response = {
        total_count: 1,
        items: [ user_matcher(user_2, include_private_data: true) ]
      }

      expect(response.body_as_hash).to match(expected_response)
    end

    it "should allow sort by multiple fields in different directions" do
      api_get :index, trusted_application_token, params: {
        q: 'last_name:jones', order_by: "first_name DESC"
      }

      outcome = JSON.parse(response.body)

      expect(outcome["items"].length).to eq 2
      expect(outcome["items"][0]["first_name"]).to eq "Tim"
      expect(outcome["items"][1]["first_name"]).to eq "Bob"
    end

    it "should return no results if the maximum number of results is exceeded" do
      api_get :index, trusted_application_token, params: {q: ''}
      expect(response.code).to eq('200')

      outcome = JSON.parse(response.body)

      expect(outcome["items"].length).to eq 0
      expect(outcome["total_count"]).not_to eq 0
    end
  end

  context "show" do
    before(:each) do
      allow(SetGdprData).to receive(:call) do |args|
        args[:user].is_not_gdpr_location = is_not_gdpr_location
      end
    end

    it "should let a User get his info" do
      api_get :show, user_1_token
      expect(response.code).to eq('200')
      expected_response = user_matcher(user_1, include_private_data: true)
      expect(response.body_as_hash).to match(expected_response)
    end

    it "should let a User get his info when if always_200 is set" do
      api_get :show, user_1_token, params: { always_200: true }
      expect(response.code).to eq('200')
      expected_response = user_matcher(user_1, include_private_data: true)
      expect(response.body_as_hash).to match(expected_response)
    end

    it "should not let id be specified" do
      api_get :show, user_1_token, params: { id: admin_user.id }
      expected_response = user_matcher(user_1, include_private_data: true)
      expect(response.body_as_hash).to match(expected_response)
    end

    it "should not let an application get a User without a token" do
      api_get :show, trusted_application_token, params: { id: admin_user.id }
      expect(response).to have_http_status :forbidden
    end

    it "should return an empty object if always_200 is set" do
      api_get :show, trusted_application_token, params: { always_200: true }
      expect(response).to have_http_status :ok
      expect(response.body_as_hash).to match({})
    end

    it "should return a properly formatted JSON response for low-info user" do
      api_get :show, user_1_token
      expected_response = user_matcher(user_1, include_private_data: true)
      expect(response.body_as_hash).to match(expected_response)
    end

    it "should return a properly formatted JSON response for user with name" do
      user_2.salesforce_contact_id = 'blah'
      user_2.save

      api_get :show, user_2_token

      expect(response.body_as_hash).to match(user_matcher(user_2, include_private_data: true))
    end

    it 'should include contact infos' do
      unconfirmed_email = AddEmailToUser.call("unconfirmed@example.com", user_1).outputs.email

      confirmed_email = AddEmailToUser.call("confirmed@example.com", user_1).outputs.email
      ConfirmContactInfo.call(confirmed_email)

      over_pinned_email = AddEmailToUser.call("over_pinned@example.com", user_1).outputs.email
      ConfirmByPin.max_pin_failures.times { ConfirmByPin.call(contact_info: over_pinned_email, pin: "whatever") }

      api_get :show, user_1_token

      expect(response.body_as_hash[:contact_infos]).to match a_collection_containing_exactly(
        {
          id: unconfirmed_email.id,
          type: "EmailAddress",
          value: "unconfirmed@example.com",
          is_verified: false,
          num_pin_verification_attempts_remaining: ConfirmByPin.max_pin_failures,
          is_guessed_preferred: false
        },
        {
          id: confirmed_email.id,
          type: "EmailAddress",
          value: "confirmed@example.com",
          is_verified: true,
          is_guessed_preferred: true
        },
        {
          id: over_pinned_email.id,
          type: "EmailAddress",
          value: "over_pinned@example.com",
          is_verified: false,
          num_pin_verification_attempts_remaining: 0,
          is_guessed_preferred: false
        }
      )
    end

    it "should include self_reported_school when present" do
      user_2.self_reported_school = "Rice University"
      user_2.save

      api_get :show, user_2_token
      expect(response.body_as_hash).to include(
        self_reported_school: "Rice University",
      )
    end

    it 'should include self_reported_role when present' do
      user_2.role = :instructor
      user_2.save

      api_get :show, user_2_token
      expect(response.body_as_hash).to include(
        self_reported_role: "instructor",
      )
    end

    context "gdpr location" do
      let(:is_not_gdpr_location) { true }

      it "reports gdpr location flag" do
        api_get :show, user_1_token
        # expected_response = user_matcher(user_1, include_private_data: true)
        expect(response.body_as_hash).to include(is_not_gdpr_location: true)
      end
    end
  end

  context "update" do
    it "should let User update their own name" do
      api_put :update, user_2_token, body: { first_name: "Jerry", last_name: "Mouse" }
      expect(response.code).to eq('200')
      user_2.reload
      expect(user_2.first_name).to eq 'Jerry'
      expect(user_2.last_name).to eq 'Mouse'
    end

    it "should not let id be specified" do
      api_put :update, user_2_token, body: { first_name: "Jerry", last_name: "Mouse" },
                                     params: { id: admin_user.id }
      expect(response.code).to eq('200')
      user_2.reload
      admin_user.reload
      expect(user_2.first_name).to eq 'Jerry'
      expect(user_2.last_name).to eq 'Mouse'
      expect(admin_user.first_name).not_to eq 'Jerry'
      expect(admin_user.last_name).not_to eq 'Mouse'
    end

    it "should not let an application update a User without a token" do
      api_put :update, trusted_application_token, params: { id: admin_user.id }
      expect(response).to have_http_status :forbidden
    end

    it "should not let a user's contact info be modified through the users API" do
      original_contact_infos = user_2.reload.contact_infos
      api_put :update, user_2_token,
                       body: {
                         first_name: "Jerry",
                         last_name: "Mouse",
                         contact_infos: [
                           {
                             id: user_2.contact_infos.first.id,
                             value: "howdy@doody.com"
                           }
                         ]
                       }
      expect(response.code).to eq('200')
      user_2.reload
      expect(user_2.contact_infos).to eq original_contact_infos
    end
  end

  context "find" do
    let(:trusted_application) do
      FactoryBot.create :doorkeeper_application, can_find_or_create_accounts: true
    end
    let(:trusted_application_token) do
      FactoryBot.create :doorkeeper_access_token, application: trusted_application,
                                                  resource_owner_id: nil
    end

    let(:user)         { FactoryBot.create :user }
    let!(:external_id) { FactoryBot.create :external_id, user: user }
    let(:valid_external_id_body) { { external_id: external_id.external_id, sso: 'true' } }
    let(:valid_uuid_body)        { { uuid: user.uuid } }

    it "should find a user by external_id for a trusted app" do
      api_post :find,
                trusted_application_token,
                body: valid_external_id_body
      expect(response).to have_http_status :ok
      expect(response.body_as_hash).to match(
        external_ids: [ external_id.external_id ],
        id: user.id,
        sso: kind_of(String),
        uuid: user.uuid
      )
    end

    it "should find a user by uuid for a trusted app" do
      api_post :find,
                trusted_application_token,
                body: valid_uuid_body
      expect(response).to have_http_status :ok
      expect(response.body_as_hash).to match(
        external_ids: [ external_id.external_id ],
        id: user.id,
        uuid: user.uuid
      )
    end

    it "should not find a user that does not exist" do
      api_post :find,
                trusted_application_token,
                body: { external_id: SecureRandom.uuid, sso: 'true' }
      expect(response).to have_http_status :not_found
    end

    it "should not find a user for anonymous" do
      api_post :find,
              nil,
              body: valid_external_id_body
      expect(response).to have_http_status :forbidden
    end

    it "should not find a user for another user" do
      api_post :find,
              user_2_token,
              body: valid_external_id_body
      expect(response).to have_http_status :forbidden
    end
  end

  context "find or create" do
    let!(:foc_trusted_application) do
      FactoryBot.create :doorkeeper_application, can_find_or_create_accounts: true
    end
    let!(:foc_trusted_application_token) do
      FactoryBot.create :doorkeeper_access_token, application: foc_trusted_application,
                                                  resource_owner_id: nil
    end

    it "should create a new user for an app" do
      expect do
        api_post :find_or_create,
                 foc_trusted_application_token,
                 body: {email: 'a-new-email@test.com', first_name: 'Ezekiel', last_name: 'Jones'}
      end.to change { User.count }.by(1)
      expect(response.code).to eq('201')
      new_user = User.order(:id).last
      expect(response.body_as_hash).to eq(
        id: new_user.id, uuid: new_user.uuid, external_ids: []
      )
    end

    it 'creates a new user with first name, last name and full name if given' do
      expect do
        api_post :find_or_create,
                 foc_trusted_application_token,
                 body: {
                   email: 'a-new-email@test.com',
                   first_name: 'Sarah',
                   last_name: 'Test',
                   role: 'instructor'
                 }
      end.to change { User.count }.by(1)
      expect(response.code).to eq('201')
      new_user = User.find(JSON.parse(response.body)['id'])
      expect(new_user.first_name).to eq 'Sarah'
      expect(new_user.last_name).to eq 'Test'
      expect(new_user.full_name).to eq 'Sarah Test'
      expect(new_user.role).to eq 'instructor'
      expect(new_user.applications).to eq [ foc_trusted_application ]
      expect(new_user.uuid).not_to be_blank
    end

    it 'creates an external user with an external_id and no username or email' do
      external_id = "#{SecureRandom.uuid}/#{SecureRandom.uuid}"

      expect do
        api_post :find_or_create,
                 foc_trusted_application_token,
                 body: {
                   external_id: external_id,
                   role: 'student',
                   sso: 'true'
                 }
      end.to change { User.count }.by(1)
      expect(response.code).to eq('201')
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['external_ids']).to eq [ external_id ]

      new_user = User.find(parsed_response['id'])
      expect(new_user.external_ids.first.external_id).to eq external_id
      expect(new_user.state).to eq 'external'
      expect(new_user.role).to eq 'student'
      expect(new_user.applications).to eq [ foc_trusted_application ]
      expect(new_user.uuid).to eq parsed_response['uuid']

      sso_cookie = parsed_response['sso']
      sso_hash = SsoCookie.read sso_cookie
      expect(sso_hash['sub']).to eq Api::V1::UserRepresenter.new(new_user).to_hash
      expect(sso_hash['exp']).to be <= (
        Time.current + Api::V1::UsersController::SSO_TOKEN_INITIAL_DURATION
      ).to_i
      expect(sso_hash['exp']).to be >= (
        Time.current + Api::V1::UsersController::SSO_TOKEN_MIN_DURATION
      ).to_i

      # Ensure the Doorkeeper token exists
      Doorkeeper::AccessToken.find_by! token: sso_cookie
    end

    it "should not create a new user for anonymous" do
      user_count = User.count
      api_post :find_or_create,
               nil,
               body: { email: 'a-new-email@test.com' }
      expect(response).to have_http_status :forbidden
      expect(User.count).to eq user_count
    end

    it "should not create a new user for another user" do
      user_count = User.count
      api_post :find_or_create,
               user_2_token,
               body: { email: 'a-new-email@test.com' }
       expect(response).to have_http_status :forbidden
      expect(User.count).to eq user_count
    end

    context "should return only IDs for a user" do
      it "does so for unclaimed users" do
        api_post :find_or_create, foc_trusted_application_token,
                 body: { username: unclaimed_user.username }
        expect(response.code).to eq('201')
        expect(response.body_as_hash).to eq(
          id: unclaimed_user.id,
          uuid: unclaimed_user.uuid,
          external_ids: []
        )
      end

      it "does so for claimed users" do
        api_post :find_or_create,
                 foc_trusted_application_token,
                 body: { email: user_2.contact_infos.first.value }
        expect(response.code).to eq('201')
        expect(response.body_as_hash).to eq(
          id: user_2.id, uuid: user_2.uuid, external_ids: []
        )
      end
    end
  end

  context "create_external_id" do
    let(:trusted_application) do
      FactoryBot.create :doorkeeper_application, can_find_or_create_accounts: true
    end
    let(:trusted_application_token) do
      FactoryBot.create :doorkeeper_access_token, application: trusted_application,
                                                  resource_owner_id: nil
    end

    let(:user)       { FactoryBot.create :user }
    let(:valid_body) { { user_id: user.id, external_id: SecureRandom.uuid } }

    it "should create a new external id for a trusted app" do
      expect do
        api_post :create_external_id,
                 trusted_application_token,
                 body: valid_body
      end.to change { ExternalId.count }.by(1)
      expect(response).to have_http_status :created
      expect(response.body_as_hash).to eq(
        user_id: valid_body[:user_id], external_id: valid_body[:external_id]
      )
    end

    it "should not create a new external id for a user that does not exist" do
      expect do
        api_post :create_external_id,
                 trusted_application_token,
                 body: { user_id: 0, external_id: SecureRandom.uuid }
      end.not_to change { ExternalId.count }
      expect(response).to have_http_status :unprocessable_entity
    end

    it "should not create an external id for anonymous" do
      expect do
        api_post :create_external_id,
                nil,
                body: valid_body
      end.not_to change { ExternalId.count }
      expect(response).to have_http_status :forbidden
    end

    it "should not create a new user for another user" do
      expect do
        api_post :create_external_id,
                user_2_token,
                body: valid_body
      end.not_to change { ExternalId.count }
      expect(response).to have_http_status :forbidden
    end
  end
end
