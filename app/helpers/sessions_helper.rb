module SessionsHelper

  def authentications_list(authentications, scope)
    providers = authentications.collect{|auth| auth.provider}
    provider_list(providers, :all, scope)
  end

  def remaining_authentications_list(authentications, scope)
    providers = authentications.collect{|auth| auth.provider}
    provider_list(%w(facebook twitter google identity) - providers, :any, scope)
  end

  def provider_list(providers, kind, scope)
    list = []

    list.push(:facebook)          if providers.include?('facebook')
    list.push(:twitter)           if providers.include?('twitter')
    list.push(:google)            if providers.include?('google_oauth2')
    list.push(:simple_password)   if providers.include?('identity')

    return I18n.enumerate kind, list, scope: scope
  end

  def suggested_login_username
    if !params[:username_or_email] &&
       signup_state.try!(:signed?) &&
       LookupUsers.by_verified_email(signup_state.signed_data['email'])

      return signup_state.signed_data['email']
    end
    params[:username_or_email]
  end

end
