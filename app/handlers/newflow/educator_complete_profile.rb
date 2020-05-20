module Newflow
  class EducatorCompleteProfile
    lev_handler

    paramify :signup do
      attribute :educator_specific_role, type: String
      attribute :other_role_name, type: String
      attribute :how_are_books_chosen, type: String
      attribute :using_openstax_how, type: String
      attribute :num_students_per_semester_taught, type: Integer
      attribute :subjects_of_interest, type: Object
      attribute :books_used, type: Object
      # attribute :subjects_of_interest #, type: Array[String]
      # attribute :books_used #, type: Array[String]

      validates(
        :educator_specific_role,
        inclusion: {
          in: %w(instructor administrator other),
        }
      )

      validates(
        :num_students_per_semester_taught,
        numericality: {
          only_integer: true,
          # greater_than_or_equal_to: 0,
          # less_than: 1_000
        }
      )
    end

    protected ###############

    def authorized?
      !caller.is_anonymous?
    end

    def handle
      caller.update(state: User::EDUCATOR_COMPLETE_PROFILE)
      transfer_errors_from(caller, {type: :verbatim}, true)

      push_lead_to_salesforce
    end

    private #################

    def push_lead_to_salesforce
      if Settings::Salesforce.push_leads_enabled
        PushSalesforceLead.perform_later(
          user: caller,
          salesforce_contact_id: caller.salesforce_contact_id, # Note: this is expected to trigger an update on an existing SalesForce Contact, as opposed to creating a new lead.
          num_students: signup_params.num_students_per_semester_taught,
          using_openstax: signup_params.using_openstax_how,
          subject: books_or_subjects,

          # TODO: salesforce must be ready to accept these before we try to push them
          # more_specific_educator_role: signup_params.educator_specific_role || signup_params.other_role_name,
          # titles: signup_params.books_used.join(';'),

          # do not set source_application because this faculty access endpoint does
          # not have a strong indication of where the user is coming from
          # TODO: carried that ^ over from the old flow... double check that it's still true.
          source_application: nil
        )
      end
    end

    def books_or_subjects
      subjects = signup_params.subjects_of_interest.reject{ |s| s == '' }
      titles = signup_params.books_used.reject{ |b| b == '' }

      if subjects.size >  0
        return subjects.join(';')
      elsif titles.size > 0
        return titles.join(';')
      end
    end


    # def salesforce_string_for_using_openstax_how
      # t('.instructor_use.fully'), 'Confirmed Adoption Won'],
      # t('.instructor_use.recommended'), 'Confirmed Will Recommend'],
      # t('.instructor_use.interested'), 'High Interest in Adopting'],
    # end

    # def validate_params_presence(required_params)
    #   begin
    #       signup_params.deep_fetch("#{required_params.keys[0]}", "#{required_params.value[0]}")
    #     end
    #   rescue KeyError => ee
    #     missing_param_error(param)
    #   end
    # end

    # def missing_param_error(field)
    #   code = "#{field}_is_blank".to_sym
    #   message = I18n.t(:"login_signup_form.#{code}")
    #   nonfatal_error(
    #     code: code,
    #     message: message,
    #     offending_inputs: field
    #   )
    # end

    # def signup_params
    #   # Defines `deepfetch`
    #   # https://github.com/hashie/hashie#deepfetch
    #   @signup_params ||= params.extend Hashie::Extensions::DeepFetch
    # end

  end
end
