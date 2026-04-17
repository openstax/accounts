module Newflow
  module EducatorSignupHelper
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
      I18n.t(scoped, default: I18n.t("educator_profile_form.#{key}"))
    end

  end
end
