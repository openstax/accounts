require 'rails_helper'

RSpec.describe OXPosthog, type: :lib do
  let(:posthog_client) { instance_double(PostHog::Client) }

  let(:school) do
    FactoryBot.create(:school,
      name: 'Test University',
      city: 'Houston',
      state: 'TX',
      country: 'United States',
      type: 'College/University (4)',
      location: 'Domestic',
      has_assignable_contacts: true,
    )
  end

  let(:user) do
    FactoryBot.create(:user,
      state: User::ACTIVATED,
      role: :instructor,
      faculty_status: 'confirmed_faculty',
      school: school,
      adopter_status: 'current_adopter',
      using_openstax_how: :as_primary,
      school_type: :college,
      school_location: :domestic_school,
      is_profile_complete: true,
      is_sheerid_verified: true,
      which_books: 'Biology',
      how_many_students: '100-200',
      title_1_school: false,
      grant_tutor_access: true,
      country_code: 'US',
      receive_newsletter: true,
      is_administrator: false,
      is_newflow: true,
      salesforce_contact_id: 'sf_contact_123',
      salesforce_lead_id: 'sf_lead_456',
    )
  end

  before do
    allow(Rails.env).to receive(:test?).and_return(false)
    allow(described_class).to receive(:posthog).and_return(posthog_client)
    allow(posthog_client).to receive(:capture)
    allow(posthog_client).to receive(:group_identify)
  end

  describe '.log' do
    it 'captures an event with all $set person properties' do
      described_class.log(user, 'signed_up')

      expect(posthog_client).to have_received(:capture).with(
        hash_including(
          distinct_id: user.uuid,
          event: 'signed_up',
          properties: hash_including(
            '$set': hash_including(
              email: user.best_email_address_for_salesforce,
              name: user.full_name,
              role: 'instructor',
              faculty_status: 'confirmed_faculty',
              school: school.id,
              salesforce_contact_id: 'sf_contact_123',
              salesforce_lead_id: 'sf_lead_456',
              adopter_status: 'current_adopter',
              using_openstax_how: 'as_primary',
              account_state: User::ACTIVATED,
              school_type: 'college',
              school_location: 'domestic_school',
              is_profile_complete: true,
              is_sheerid_verified: true,
              which_books: 'Biology',
              how_many_students: '100-200',
              country_code: 'US',
              receive_newsletter: true,
              is_administrator: user.is_administrator,
              has_external_id: false,
            )
          )
        )
      )
    end

    it 'includes $set_once with timestamps and signup_flow' do
      described_class.log(user, 'signed_up')

      expect(posthog_client).to have_received(:capture).with(
        hash_including(
          properties: hash_including(
            '$set_once': hash_including(
              uuid: user.uuid,
              created_at: user.created_at.iso8601,
              signup_flow: 'newflow',
            )
          )
        )
      )
    end

    it 'sets signup_flow to legacy when is_newflow is false' do
      user.update!(is_newflow: false)
      described_class.log(user, 'signed_up')

      expect(posthog_client).to have_received(:capture).with(
        hash_including(
          properties: hash_including(
            '$set_once': hash_including(signup_flow: 'legacy')
          )
        )
      )
    end

    it 'includes activated_at in $set_once when present' do
      user.update!(activated_at: Time.zone.parse('2025-06-15T12:00:00Z'))
      described_class.log(user, 'signed_up')

      expect(posthog_client).to have_received(:capture).with(
        hash_including(
          properties: hash_including(
            '$set_once': hash_including(activated_at: user.activated_at.iso8601)
          )
        )
      )
    end

    it 'merges extra_props into the event properties' do
      described_class.log(user, 'signed_up', source: 'educator_flow')

      expect(posthog_client).to have_received(:capture).with(
        hash_including(
          properties: hash_including(source: 'educator_flow')
        )
      )
    end

    it 'includes school group association when user has a school' do
      described_class.log(user, 'signed_up')

      expect(posthog_client).to have_received(:capture).with(
        hash_including(groups: { school: school.id.to_s })
      )
    end

    it 'calls identify_school when user has a school' do
      described_class.log(user, 'signed_up')

      expect(posthog_client).to have_received(:group_identify).with(
        hash_including(
          group_type: 'school',
          group_key: school.id.to_s,
        )
      )
    end

    context 'when user has no school' do
      before { user.update!(school: nil) }

      it 'does not include groups in the capture' do
        described_class.log(user, 'signed_up')

        expect(posthog_client).to have_received(:capture).with(
          hash_excluding(:groups)
        )
      end

      it 'does not call identify_school' do
        described_class.log(user, 'signed_up')

        expect(posthog_client).not_to have_received(:group_identify)
      end
    end

    it 'uses best_email_address_for_salesforce for email' do
      email = FactoryBot.create(:email_address, user: user, verified: true)
      user.reload

      described_class.log(user, 'signed_up')

      expect(posthog_client).to have_received(:capture).with(
        hash_including(
          properties: hash_including(
            '$set': hash_including(email: user.best_email_address_for_salesforce)
          )
        )
      )
    end

    context 'guard clauses' do
      it 'returns early for nil user' do
        described_class.log(nil, 'signed_up')

        expect(posthog_client).not_to have_received(:capture)
      end

      it 'returns early for anonymous user' do
        anon = AnonymousUser.instance
        described_class.log(anon, 'signed_up')

        expect(posthog_client).not_to have_received(:capture)
      end
    end

    context 'error handling' do
      it 'captures exceptions with Sentry when capture raises' do
        error = RuntimeError.new('PostHog connection failed')
        allow(posthog_client).to receive(:capture).and_raise(error)

        expect(Sentry).to receive(:capture_exception).with(error)

        described_class.log(user, 'signed_up')
      end
    end
  end

  describe '.identify_school' do
    it 'sends all school properties via group_identify' do
      described_class.identify_school(school)

      expect(posthog_client).to have_received(:group_identify).with(
        group_type: 'school',
        group_key: school.id.to_s,
        properties: {
          name: 'Test University',
          salesforce_id: school.salesforce_id,
          city: 'Houston',
          state: 'TX',
          country: 'United States',
          type: 'College/University (4)',
          location: 'Domestic',
          has_assignable_contacts: true,
        }
      )
    end

    it 'returns early for nil school' do
      described_class.identify_school(nil)

      expect(posthog_client).not_to have_received(:group_identify)
    end

    it 'captures exceptions with Sentry when group_identify raises' do
      error = RuntimeError.new('PostHog group_identify failed')
      allow(posthog_client).to receive(:group_identify).and_raise(error)

      expect(Sentry).to receive(:capture_exception).with(error)

      described_class.identify_school(school)
    end
  end
end
