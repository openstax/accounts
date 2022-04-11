module ProfileHelper

  def way_to_login(provider:, user_authentications: nil, has_authentication: nil, current_providers:)
    if has_authentication.nil?
      if user_authentications.nil?
        raise "At least one of user_authentications or has_authentication must be set"
      end

      has_authentication = user_authentications.any?{|auth| auth.provider == provider}
    end

    icon_class, display_name =
      case provider
      when 'identity' then ['key', (I18n.t :"users.edit.password")]
      when 'google_oauth2' then ['google', 'Google']
      when 'facebooknewflow' then ['facebook', 'Facebook']
      when 'googlenewflow' then ['google', 'Google']
      else [ provider, provider.capitalize ]
      end

    icons = [
      'glyphicon-pencil edit--newflow', 'glyphicon-trash delete--newflow', 'glyphicon-plus add--newflow',
    ]

    snippet = <<-SNIPPET
      <span class="icon fa-stack fa-lg">
        <i class="fa fa-square fa-stack-2x #{provider}-bkg"></i>
        <i class="fa fa-#{icon_class} fa-stack-1x fa-inverse"></i>
      </span>
      <span class="name">#{display_name}</span>
      <span class="mod-holder">
      #{icons.map{|icon| "<span class='glyphicon #{icon} mod'></span>"}.join}
      </span>
    SNIPPET

    "<div class='authentication' data-provider='#{provider}'>#{snippet}</div>".html_safe
  end

  def email_entry(value:, id:, is_verified:, is_searchable:)
    verify_link = is_verified ? '' : ""
    unconfirmed_link = is_verified ? '' : <<-EOV
      <span class='unconfirmed-warning'>[<span class='msg editable-click'>
        #{I18n.t(:"users.edit.unconfirmed_warning")}
      </span>]</span>
    EOV

    (
      <<-SNIPPET
        <div class="email-entry #{'verified' if is_verified}" data-id="#{id}">
          <span class="email editable-click"><span class="value">#{value}</span></span>
          #{unconfirmed_link}
          <div class="controls">
            <div class='resend-confirmation'>
              <i class='fa fa-envelope-o'></i>
              #{button_to((I18n.t :"users.edit.resend_confirmation"), resend_confirmation_contact_info_path(id: id), method: :put )}
            </div>
            <div class="delete">
              <span class="glyphicon glyphicon-trash"></span><a href="#">Delete</a>
            </div>
            <div class="searchable-toggle">
              <label><input type="checkbox" class='searchable' #{'checked="IS_SEARCHABLE"' if is_searchable}> #{I18n.t :"users.edit.searchable"}</label>
            </div>
          </div>
          <i class="spinner fa fa-spinner fa-spin fa-lg" style="display:none"></i>
        </div>
      SNIPPET
    ).html_safe
  end

end
