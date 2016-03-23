module SessionsHelper

  def authentications_list(authentications)
    providers = authentications.collect{|auth| auth.provider}
    provider_list(providers, 'and')
  end

  def remaining_authentications_list(authentications)
    providers = authentications.collect{|auth| auth.provider}
    provider_list(%w(facebook twitter google identity) - providers, 'or')
  end

  def provider_list(providers, conjunction)
    list = []

    list.push('Facebook')          if providers.include?('facebook')
    list.push('Twitter')           if providers.include?('twitter')
    list.push('Google')            if providers.include?('google_oauth2')
    list.push('a simple password') if providers.include?('identity')

    if list.size >= 2
      list[list.size-1] = "#{conjunction} " + list[list.size-1]
    end

    list.size >= 3 ? list.join(', ') : list.join(' ')
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
