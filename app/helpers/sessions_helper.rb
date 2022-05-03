module SessionsHelper

  def authentications_list(authentications, scope)
    providers = authentications.collect{|auth| auth.provider}
    provider_list(providers, :all, scope)
  end

  def remaining_authentications_list(authentications, scope)
    providers = authentications.collect{|auth| auth.provider}
    provider_list(%w(facebook google_oauth2 identity) - providers, :any, scope)
  end

  def provider_list(providers, kind, scope)
    list = []

    list.push(:facebook)          if providers.include?('facebook')
    list.push(:google_oauth2)     if providers.include?('google_oauth2')
    list.push(:simple_password)   if providers.include?('identity')

    return I18n.enumerate kind, list, scope: scope
  end
end
