require 'posthog'

class OXPosthog
  def self.posthog
    @posthog ||= PostHog::Client.new(
      api_key: Rails.application.secrets.posthog_project_api_key,
      host: "https://us.i.posthog.com",
      on_error: Proc.new { |status, msg| Rails.logger.error("[PostHog] Error #{status}: #{msg}") },
      test_mode: Rails.env.test?,
    )
  end

  # Capture a named event for a user from anywhere in the app (controllers, handlers, jobs, etc.)
  # extra_props are merged into the event at the top level (alongside $set/$set_once).
  def self.log(user, event, extra_props = {})
    return if user.nil? || user.is_anonymous? || Rails.env.test?
    attrs = {
      distinct_id: user.uuid,
      event: event,
      properties: {
        '$set': {
          email: user.best_email_address_for_salesforce,
          name: user.full_name,
          role: user.role,
          faculty_status: user.faculty_status,
          school: user.school&.id,
          recent_authentication_provider: user.authentications&.last&.provider,
          authentication_method_count: user.authentications&.count,
          salesforce_contact_id: user.salesforce_contact_id,
          salesforce_lead_id: user.salesforce_lead_id,
          adopter_status: user.adopter_status,
          using_openstax_how: user.using_openstax_how,
          account_state: user.state,
          school_type: user.school_type,
          school_location: user.school_location,
          is_profile_complete: user.is_profile_complete,
          is_sheerid_verified: user.is_sheerid_verified,
          which_books: user.which_books,
          how_many_students: user.how_many_students,
          country_code: user.country_code,
          receive_newsletter: user.receive_newsletter,
          is_administrator: user.is_administrator,
          has_external_id: user.has_external_id?,
        },
        '$set_once': {
          uuid: user.uuid,
          created_at: user.created_at&.iso8601,
          activated_at: user.activated_at&.iso8601,
          signup_flow: user.is_newflow ? 'newflow' : 'legacy',
        },
        **extra_props
      }
    }
    attrs[:groups] = { school: user.school.id.to_s } if user.school
    posthog.capture(attrs)
    identify_school(user.school) if user.school
  rescue StandardError => e
    Sentry.capture_exception(e)
  end

  def self.identify_school(school)
    return if school.nil? || Rails.env.test?
    posthog.group_identify(
      group_type: 'school',
      group_key: school.id.to_s,
      properties: {
        name: school.name,
        salesforce_id: school.salesforce_id,
        city: school.city,
        state: school.state,
        country: school.country,
        type: school.type,
        location: school.location,
        has_assignable_contacts: school.has_assignable_contacts,
      }
    )
  rescue StandardError => e
    Sentry.capture_exception(e)
  end
end
