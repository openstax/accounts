class SignupPassword

  lev_handler

  paramify :register do
    attribute :i_agree, type: boolean
    attribute :username, type: String
    validates :username, presence: true
    attribute :title, type: String
    attribute :first_name, type: String
    validates :first_name, presence: true
    attribute :last_name, type: String
    validates :last_name, presence: true
    attribute :suffix, type: String
    attribute :email_address, type: String
    validates :email_address, presence: true
    attribute :password, type: String
    attribute :password_confirmation, type: String
    attribute :contract_1_id, type: Integer
    attribute :contract_2_id, type: Integer
  end

  uses_routine CreateUser,
               translations: { inputs: {scope: :register} }
  uses_routine CreateIdentity,
               translations: { inputs:  {scope: :register},
                               outputs: {type: :verbatim}  }
  uses_routine AddEmailToUser,
               translations: { inputs: {scope: :register} }
  uses_routine AgreeToTerms

  protected

  def authorized?
    OSU::AccessPolicy.action_allowed?(:register, caller, caller)
  end

  def handle
    # user = caller

    # if (options[:is_password_signup] ^ !user.is_anonymous?)
    #   fatal_error(code: :inconsistent_state)
    # end

    if options[:contracts_required] && !register_params.i_agree
      fatal_error(code: :did_not_agree, message: 'You must agree to the terms to create your account.')
    end

    # if options[:is_password_signup]
      run(CreateUser, username: register_params.username)
      user = outputs[[:create_user, :user]]
    # end

    user.username = register_params.username
    user.title = register_params.title if !register_params.title.blank?
    user.first_name = register_params.first_name
    user.last_name = register_params.last_name
    user.suffix = register_params.suffix if !register_params.suffix.blank?
    user.state = 'activated'
    user.save

    transfer_errors_from(user, {type: :verbatim}, true)

    # If this is a password signup, create the Identity record.  Don't create
    # an authentication yet, that is the job for SessionsCallback.

    # if options[:is_password_signup]
      if register_params.password.blank? || register_params.password_confirmation.blank?
        fatal_error(code: :passwords_missing, message: "You must choose a password and confirm it to create your account.")
      else
        run(CreateIdentity,
            password:              register_params.password,
            password_confirmation: register_params.password_confirmation,
            user_id:               user.id
        )
      end
    # end

    # Doesn't hurt to readd the email if already verified by social login
    run(AddEmailToUser, register_params.email_address, user)

    transfer_errors_from(user, {type: :verbatim}, true)

    if options[:contracts_required]
      run(AgreeToTerms, register_params.contract_1_id, user, no_error_if_already_signed: true)
      run(AgreeToTerms, register_params.contract_2_id, user, no_error_if_already_signed: true)
    end

    # attach_user_to_person
  end

  # def attach_user_to_person
  #   person = Person.create!
  #   user.person_id = person.id
  #   user.save

  #   transfer_errors_from(user, {type: :verbatim})
  # end
end
