# Replacement for SessionsCreate handler.
# Handles the omniauth callback.
#
class NewflowSocialCallback
  include Rails.application.routes.url_helpers

  lev_handler

  protected #######################

  def authorized?
    true
  end

  def setup
    @came_from = URI.parse(request.env['omniauth.origin']).path
    @data = OmniauthData.new(request.env['omniauth.auth']) \
                        rescue fatal_error(code: :invalid_omniauth_data)
  end

  def handle
    # TODO: might want to undo the following line when we deploy to production
    social_provider = @data.provider == 'facebooknewflow' ? 'facebook' : @data.provider

    if logging_in?
      authentication = Authentication.find_by(
        provider: social_provider, uid: @data.uid.to_s
      )
      outputs.user = authentication.user
    elsif signing_up?
      # Create user
      user = User.create!(
        state: 'activated',
        first_name: @data.name.split("\s")[0],
        last_name: @data.name.split("\s").drop(1).join(' ')
      )
      # Create authentication provider
      authentication = Authentication.create(
        provider: social_provider, uid: @data.uid.to_s, user_id: user.id
      )
      transfer_errors_from(authentication, { scope: :authentication }, true) # TODO: correct scope?
      # Create email address
      email_address = EmailAddress.find_or_create_by(value: @data.email)
      # email_address = EmailAddress.create(value: @data.email)
      email_address.user = user
      email_address.verified = true # we trust facebook and google
      email_address.save
      transfer_errors_from(email_address, { scope: :email_address }, true)
      outputs.user = authentication.user
    else
      raise('edge case')
    end
  end

  private #######################

  def logging_in?
    @came_from == newflow_login_path
  end

  def signing_up?
    @came_from == newflow_signup_path
  end
end
