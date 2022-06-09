module EducatorSignup
  class SignupForm

    USER_DEFAULT_STATE = :unverified
    USER_FACULTY_STATUS = User::PENDING_FACULTY
    USER_ROLE = :instructor
    private_constant(:USER_DEFAULT_STATE, :USER_FACULTY_STATUS, :USER_ROLE)

    lev_handler

    uses_routine AgreeToTerms
    uses_routine CreateEmailForUser
    uses_routine SetPassword, translations: {
      outputs: {
        map: { identity: :password },
        scope: :password
      }
    }

    paramify :signup do
      attribute :first_name, type: String
      attribute :last_name, type: String
      attribute :email, type: String
      attribute :password, type: String
      attribute :is_title_1_school, type: boolean
      attribute :newsletter, type: boolean
      attribute :terms_accepted, type: boolean
      attribute :contract_1_id, type: Integer
      attribute :contract_2_id, type: Integer
      attribute :role, type: String
      attribute :phone_number, type: String
      attribute :country_code, type: String
    end

    def required_params
      @required_params ||= [:email, :first_name, :last_name, :password, :phone_number, :terms_accepted]
    end

    protected #################

    def authorized?
      true
    end

    def handle
      validate_presence_of_required_params
      return if errors?

      outputs.email = signup_params.email.squish!

      if LookupUsers.by_verified_email(signup_params.email.squish!).first
        fatal_error(
          code: :email_taken,
          message: I18n.t(:"login_signup_form.email_address_taken"),
          offending_inputs: :email
        )
      end


      outputs.user = create_user


      run(::SetPassword,
        user: outputs.user,
        password: signup_params.password,
        password_confirmation: signup_params.password
      )

      agree_to_terms

      if options[:is_BRI_book]
        outputs.user.is_b_r_i_user = true
        outputs.user.title_1_school = signup_params.is_title_1_school
        outputs.user.save!
      end

      run(CreateEmailForUser, email: signup_params.email, user: outputs.user)
    end

    private ###################

    def create_user
      user = User.create(
        state: USER_DEFAULT_STATE,
        role: USER_ROLE,
        faculty_status: USER_FACULTY_STATUS,
        first_name: signup_params.first_name,
        last_name: signup_params.last_name,
        phone_number: signup_params.phone_number,
        country_code: signup_params.country_code,
        receive_newsletter: signup_params.newsletter,
        source_application: options[:client_app],
      )
      transfer_errors_from(user, { type: :verbatim }, :fail_if_errors)
      user
    end

    def agree_to_terms
      return unless options[:contracts_required]

      run(AgreeToTerms, signup_params.contract_1_id, outputs.user, no_error_if_already_signed: true)
      run(AgreeToTerms, signup_params.contract_2_id, outputs.user, no_error_if_already_signed: true)
    end

    def validate_presence_of_required_params
      required_params.each do |param|
        if signup_params.send(param).blank?
          missing_param_error(param)
        end
      end
    end

    def missing_param_error(field)
      code = "#{field}_is_blank".to_sym
      message = I18n.t(:"login_signup_form.#{code}")
      nonfatal_error(
        code: code,
        message: message,
        offending_inputs: field
      )
    end

  end
end
