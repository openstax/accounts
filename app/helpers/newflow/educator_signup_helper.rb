module Newflow
  module EducatorSignupHelper
    # Session flag set when the user clicks the "use my current email
    # anyway" affordance on the SheerID school-email gate, so it doesn't
    # resurface on refresh/back for the rest of this signup session.
    SKIP_SCHOOL_EMAIL_GATE_SESSION_KEY = :sheerid_skip_school_email_gate

    def sheerid_provided_verification_id_param
      params[:verificationid]
    end

    def is_school_not_supported_by_sheerid?
      params[:school].present?
    end

    def is_country_not_supported_by_sheerid?
      params[:country].present?
    end

    def should_show_school_issued_email_field?
      is_cs_form?
    end

    def is_cs_form?
      request.original_fullpath.include? 'cs_form'
    end

    def user
      current_user
    end

    def educator_copy_audience
      case user&.school_type
      when 'k12_school', 'high_school', 'home_school' then :k12
      else :default
      end
    end

    def educator_copy(key)
      scoped = "educator_profile_form.#{educator_copy_audience}.#{key}"
      I18n.t(scoped, default: :"educator_profile_form.#{key}")
    end

    # The email currently "on file" for the user at the SheerID step -
    # i.e. before any school email has been added via the gate below.
    def on_file_email_for_sheerid
      user&.best_email_address_for_salesforce
    end

    # Guidance heuristic, not a hard block: true when the user's on-file
    # email doesn't look like a school address (per
    # EmailAddress.looks_like_school_email?). A user who insists can
    # still proceed to SheerID with that email anyway.
    def current_email_looks_personal?
      email = on_file_email_for_sheerid
      email.present? && !EmailAddress.looks_like_school_email?(email)
    end

    def show_school_email_gate?
      !session[SKIP_SCHOOL_EMAIL_GATE_SESSION_KEY] && current_email_looks_personal?
    end

  end
end
