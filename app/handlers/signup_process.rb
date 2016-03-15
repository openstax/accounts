class SignupProcess

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
  uses_routine FinishUserCreation

  protected

  def authorized?
    OSU::AccessPolicy.action_allowed?(:register, caller, caller)
  end

  def handle
    if options[:contracts_required] && !register_params.i_agree
      fatal_error(code: :did_not_agree, message: 'You must agree to the terms to create your account.')
    end

    user = caller

    # TODO just added this recently still need it?
    # if user.identity
    #   outputs[:identity] = user.identity # let the sign up flow continue
    #   fatal_error(code: :already_has_identity)
    # end

    if user.is_anonymous?
      run(CreateUser, username: register_params.username)
      user = outputs[[:create_user, :user]]
    end

    user.username = register_params.username
    user.title = register_params.title if !register_params.title.blank?
    user.first_name = register_params.first_name
    user.last_name = register_params.last_name
    user.suffix = register_params.suffix if !register_params.suffix.blank?
    user.save

    transfer_errors_from(user, {type: :verbatim}, true)

    # If the user doesn't have any authentications, then password information
    # should be available and we should make an identity authentication

    if user.authentications.none?
      # TODO turn this block into a private method `attach_password_authentication` or something
      if register_params.password.present? && register_params.password_confirmation.present?
        run(CreateIdentity,
            password:              register_params.password,
            password_confirmation: register_params.password_confirmation,
            user_id:               user.id
        )

        authentication = Authentication.create(uid: outputs[:identity].id.to_s,
                                               provider: 'identity',
                                               user_id: user.id)

        transfer_errors_from(authentication, {type: :verbatim}, true)
      else
        fatal_error(code: :passwords_missing, message: "You must choose a password and confirm it to create your account.")
      end
    end

    run(AddEmailToUser, register_params.email_address, user)

    if params[:stored_url].present?  # TODO not needed???
      user.registration_redirect_url = params[:stored_url]
      user.save
    end

    transfer_errors_from(user, {type: :verbatim}, true)

    if options[:contracts_required]
      run(AgreeToTerms, register_params.contract_1_id, user, no_error_if_already_signed: true)
      run(AgreeToTerms, register_params.contract_2_id, user, no_error_if_already_signed: true)
    end

    run(FinishUserCreation, user)  # TODO turn this into a private method if not used elsewhere
  end
end
