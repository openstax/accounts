require 'rails_helper'

RSpec.describe Admin::ImportUsers, type: :routine do

  let(:filename) { 'spec/fixtures/users.json' }

  it 'can import users' do
    expect { described_class.call(filename: filename) }.to change  { User.count }.by(3)
                                                       .and change { Identity.count }.by(2)
                                                       .and change { Authentication.count }.by(2)
                                                       .and change { ContactInfo.count }.by(2)

    users = User.order(:created_at).last(3)
    user_1 = users.first
    user_2 = users.second
    user_3 = users.third

    expect(user_1.username).to eq 'jstrav'
    expect(user_1.created_at).to eq '2018-05-17T19:49:42.469Z'
    expect(user_1.updated_at).to eq '2018-05-17T19:49:42.469Z'
    expect(user_1.is_administrator).to eq false
    expect(user_1.first_name).to eq 'John'
    expect(user_1.last_name).to eq 'Stravinsky'
    expect(user_1.title).to be_nil
    expect(user_1.uuid).to eq 'f1f96deb-919b-4183-9367-0cb713672172'
    expect(user_1.suffix).to be_nil
    expect(user_1.state).to eq 'activated'
    expect(user_1.salesforce_contact_id).to be_nil
    expect(user_1.faculty_status).to eq 'no_faculty_info'
    expect(user_1.self_reported_school).to be_nil
    expect(user_1.login_token).to be_nil
    expect(user_1.login_token_expires_at).to be_nil
    expect(user_1.role).to eq 'unknown_role'
    expect(user_1.signed_external_data).to be_nil
    expect(user_1.support_identifier).to eq 'cs_5d1edbb0'
    expect(user_1.is_test).to be_nil
    expect(user_1.school_type).to eq 'unknown_school_type'
    expect(user_1.identity.password_digest).to(
      eq '$2a$04$s48G.v95rrx3vQ9Hvld2fus2fuNBRBhel99Io30.mTJOivtSgSxRu'
    )
    expect(user_1.identity.created_at).to eq '2018-05-17T19:49:42.524Z'
    expect(user_1.identity.updated_at).to eq '2018-05-17T19:49:42.524Z'
    expect(user_1.identity.password_expires_at).to be_nil
    expect(user_1.authentications.first.provider).to eq 'identity'
    expect(user_1.authentications.first.created_at).to eq '2018-05-17T19:49:42.538Z'
    expect(user_1.authentications.first.updated_at).to eq '2018-05-17T19:49:42.538Z'
    expect(user_1.authentications.first.login_hint).to be_nil
    expect(user_1.authentications.first.uid).to eq user_1.identity.id.to_s
    expect(user_1.contact_infos.first.type).to eq 'EmailAddress'
    expect(user_1.contact_infos.first.value).to eq '8f30b4@7cc1fa.223256'
    expect(user_1.contact_infos.first.verified).to eq false
    expect(user_1.contact_infos.first.created_at).to eq '2018-05-17T19:49:42.477Z'
    expect(user_1.contact_infos.first.updated_at).to eq '2018-05-17T19:49:42.477Z'
    expect(user_1.contact_infos.first.confirmation_sent_at).to be_nil
    expect(user_1.contact_infos.first.is_searchable).to eq true
    expect(user_1.contact_infos.second.type).to eq 'EmailAddress'
    expect(user_1.contact_infos.second.value).to eq 'a467a2@4634bc.981344'
    expect(user_1.contact_infos.second.verified).to eq false
    expect(user_1.contact_infos.second.created_at).to eq '2018-05-17T19:49:42.485Z'
    expect(user_1.contact_infos.second.updated_at).to eq '2018-05-17T19:49:42.485Z'
    expect(user_1.contact_infos.second.confirmation_sent_at).to be_nil
    expect(user_1.contact_infos.second.is_searchable).to eq true

    expect(user_2.username).to eq 'mary'
    expect(user_2.created_at).to eq '2018-05-17T19:49:42.497Z'
    expect(user_2.updated_at).to eq '2018-05-17T19:49:42.497Z'
    expect(user_2.is_administrator).to eq false
    expect(user_2.first_name).to eq 'Mary'
    expect(user_2.last_name).to eq 'Mighty'
    expect(user_2.title).to be_nil
    expect(user_2.uuid).to eq 'f3145396-9b36-4080-a66d-ff3d4c0c1393'
    expect(user_2.suffix).to be_nil
    expect(user_2.state).to eq 'activated'
    expect(user_2.salesforce_contact_id).to be_nil
    expect(user_2.faculty_status).to eq 'no_faculty_info'
    expect(user_2.self_reported_school).to be_nil
    expect(user_2.login_token).to be_nil
    expect(user_2.login_token_expires_at).to be_nil
    expect(user_2.role).to eq 'unknown_role'
    expect(user_2.signed_external_data).to be_nil
    expect(user_2.support_identifier).to eq 'cs_6cf1cf5e'
    expect(user_2.is_test).to be_nil
    expect(user_2.school_type).to eq 'unknown_school_type'
    expect(user_2.identity.password_digest).to(
      eq '$2a$04$nghthHpquanPYYJRfUk6n.TwkNtoP6h.aFFWJl9DHblRze9F1teMa'
    )
    expect(user_2.identity.created_at).to eq '2018-05-17T19:49:42.545Z'
    expect(user_2.identity.updated_at).to eq '2018-05-17T19:49:42.545Z'
    expect(user_2.identity.password_expires_at).to be_nil
    expect(user_2.authentications.first.provider).to eq 'identity'
    expect(user_2.authentications.first.created_at).to eq '2018-05-17T19:49:42.551Z'
    expect(user_2.authentications.first.updated_at).to eq '2018-05-17T19:49:42.551Z'
    expect(user_2.authentications.first.login_hint).to be_nil
    expect(user_2.authentications.first.uid).to eq user_2.identity.id.to_s
    expect(user_2.contact_infos).to be_empty

    expect(user_3.username).to eq 'jstead'
    expect(user_3.created_at).to eq '2018-05-17T19:49:42.507Z'
    expect(user_3.updated_at).to eq '2018-05-17T19:49:42.507Z'
    expect(user_3.is_administrator).to eq false
    expect(user_3.first_name).to eq 'John'
    expect(user_3.last_name).to eq 'Stead'
    expect(user_3.title).to be_nil
    expect(user_3.uuid).to eq '1ced2cd8-4bb5-4bc6-a034-29410bb6e86d'
    expect(user_3.suffix).to be_nil
    expect(user_3.state).to eq 'activated'
    expect(user_3.salesforce_contact_id).to be_nil
    expect(user_3.faculty_status).to eq 'no_faculty_info'
    expect(user_3.self_reported_school).to be_nil
    expect(user_3.login_token).to be_nil
    expect(user_3.login_token_expires_at).to be_nil
    expect(user_3.role).to eq 'unknown_role'
    expect(user_3.signed_external_data).to be_nil
    expect(user_3.support_identifier).to eq 'cs_fa68f2a5'
    expect(user_3.is_test).to be_nil
    expect(user_3.school_type).to eq 'unknown_school_type'
    expect(user_3.identity).to be_nil
    expect(user_3.authentications).to be_empty
    expect(user_3.contact_infos).to be_empty
  end

end
