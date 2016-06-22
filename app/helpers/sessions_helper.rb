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

  def last_signin_mark(provider)
    (
      <<-SNIPPET
        <div class="last-signin #{provider}" style="#{'display:none' unless provider == 'force' || last_signin_provider == provider}">
          <span class="last-signin-symbol">*</span>
        </div>
      SNIPPET
    ).html_safe
  end
end
