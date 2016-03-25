
class SignupController < ApplicationController

  skip_before_filter :authenticate_user!
  skip_before_filter :finish_sign_up

  fine_print_skip :general_terms_of_use, :privacy_policy

  def password
    @errors ||= env['errors']

    if !current_user.is_anonymous? && current_user.authentications.any?{|auth| auth.provider == 'identity'}
      redirect_to root_path, alert: "You already have a username and password on your account!"
    else
      store_fallback
    end
  end

  def social
    if request.post?
      handle_with(SignupSocial,
                  contracts_required: !contracts_not_required,
                  success: lambda {
                    set_last_signin_provider(current_user.authentications.first.provider)
                    redirect_back
                  },
                  failure: lambda {
                    errors = @handler_result.errors.any?
                    render :social, status: errors ? 400 : 200
                  })
    end
  end

end
