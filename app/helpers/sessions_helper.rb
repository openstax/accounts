module SessionsHelper


  def oauth_login_link(service, options)
    title = options[:title] || service.capitalize
    has_login  = current_user.authentications.any?{|auth| auth.provider == service }
    css_class  = has_login ? "login-button adding" : 'login-button'
    link_title = has_login ? "Sign in with a different #{title} account" : "Sign in using your #{title} account"

    link_to( "/auth/#{service}", { class: css_class, id: "#{service}-login-button" } ) do
      image_tag( options[:icon], title: link_title )
    end
  end

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
end
