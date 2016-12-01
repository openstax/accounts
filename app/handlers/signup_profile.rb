class SignupProfile

  lev_handler

  def self.include_common_params_in(paramifier)
    paramifier.instance_exec(&(proc {
      # All children of this handler should know about all of
      # these fields (because all may be used in this parent
      # handler), but only some should always be required;
      # some children will require specific ones in addition

      attribute :first_name, type: String
      attribute :last_name, type: String
      attribute :suffix, type: String
      attribute :school, type: String
      attribute :phone_number, type: String
      attribute :subjects, type: Object
      attribute :url, type: String
      attribute :num_students, type: Integer
      attribute :using_openstax, type: String
      attribute :newsletter, type: boolean
      attribute :contract_1_id, type: Integer
      attribute :contract_2_id, type: Integer

      # All children must require these fields:

      validates :first_name, presence: true
      validates :last_name, presence: true
      validates :school, presence: true
    }))
  end

  def authorized?
    caller.is_needs_profile?
    # OSU::AccessPolicy.action_allowed?(:signup, caller, caller)  # TODO was this before
  end

  def handle
    # Set profile info on user and set to activated

    caller.first_name           = profile_params.first_name
    caller.last_name            = profile_params.last_name
    caller.suffix               = profile_params.suffix      if !profile_params.suffix.blank?
    caller.state                = 'activated'
    caller.self_reported_school = profile_params.school

    caller.save

    transfer_errors_from(caller, {type: :verbatim}, true)

    # Agree to terms
    if options[:contracts_required]
      run(AgreeToTerms, profile_params.contract_1_id, caller, no_error_if_already_signed: true)
      run(AgreeToTerms, profile_params.contract_2_id, caller, no_error_if_already_signed: true)
    end

    if push_lead && Settings::Salesforce.push_leads_enabled
      # TODO: make sure the subject keys are in the correct form for Salesforce, then
      # concatenate the selected ones into the Salesforce format, e.g.:
      # "Macro Econ;Micro Econ;US History;AP Macro Econ"
      #
      # profile_params.subjects.find_all{|k,v| v == '1'}.map{|kv|
      #   Settings::Subjects[kv.first]['sf']
      # }


      PushSalesforceLead.perform_later(
        user: caller,
        role: caller.role,
        phone_number: profile_params.phone_number,
        school: caller.self_reported_school,
        num_students: profile_params.num_students,
        using_openstax: profile_params.using_openstax,
        url: profile_params.url,
        newsletter: profile_params.newsletter
      )
    end
  end

  def push_lead
    # disable by default, override in subclasses to enable
    false
  end

end
