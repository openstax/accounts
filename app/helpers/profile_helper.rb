module ProfileHelper

  def newflow_way_to_login(provider:, user_authentications: nil, has_authentication: nil, current_providers:)
    if has_authentication.nil?
      if user_authentications.nil?
        raise "At least one of user_authentications or has_authentication must be set"
      end

      has_authentication = user_authentications.any?{|auth| auth.provider == provider}
    end

    icon_class, display_name =
      case provider
      when 'identity' then ['key', (I18n.t :"legacy.users.edit.password")]
      when 'google_oauth2' then ['google', 'Google']
      when 'facebooknewflow' then ['facebook', 'Facebook']
      when 'googlenewflow' then ['google', 'Google']
      else [ provider, provider.capitalize ]
      end

    icons = [
      {'label' => 'Edit', 'fragment' => 'pencil edit'},
      {'label' => 'Delete', 'fragment' => 'trash delete'},
      {'label' => 'Add', 'fragment' => 'plus add'}
    ]

    snippet = <<-SNIPPET
      <span class="icon fa-stack fa-lg">
        <i class="fa fa-#{icon_class} fa-stack-1x"></i>
      </span>
      <span class="name">#{display_name}</span>
      <span class="mod-holder">
      #{icons.map{|icon| "<a href='#' class='glyphicon glyphicon-#{icon['fragment']}--newflow mod' aria-label='#{icon['label']} #{display_name}'></a>"}.join}
      </span>
    SNIPPET

    "<div class='authentication' data-provider='#{provider}'>#{snippet}</div>".html_safe
  end

  def way_to_login(provider:, user_authentications: nil, has_authentication: nil, current_providers:)
    if has_authentication.nil?
      if user_authentications.nil?
        raise "At least one of user_authentications or has_authentication must be set"
      end

      has_authentication = user_authentications.any?{|auth| auth.provider == provider}
    end

    icon_class, display_name =
      case provider
      when 'identity' then ['key', (I18n.t :"legacy.users.edit.password")]
      when 'google_oauth2' then ['google', 'Google']
      when 'facebooknewflow' then ['facebook', 'Facebook']
      when 'googlenewflow' then ['google', 'Google']
      else [ provider, provider.capitalize ]
      end

    icons = [
      'glyphicon-pencil edit', 'glyphicon-trash delete', 'glyphicon-plus add',
    ]

    snippet = <<-SNIPPET
      <span class="icon fa-stack fa-lg">
        <i class="fa fa-#{icon_class} fa-stack-1x"></i>
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
    unconfirmed_link =
      if is_verified || id.blank?
        ''
      else
        <<-EOV
          <span class='unconfirmed-warning'>Pending</span>
        EOV
      end

    searchable_checked = is_searchable ? 'checked="checked"' : ''

    resend_form = form_tag(resend_confirmation_contact_info_path(id: id), method: :put, class: "resend-confirmation__form") do
      button_tag(
        (I18n.t :"legacy.users.edit.resend_confirmation"),
        class: "account-security__add-email account-security__resend-button"
      )
    end

    toggle_content = if id.present?
      "
      <button type=\"button\" class=\"email-entry__toggle\" aria-label=\"Manage #{value} settings\" aria-expanded=\"false\">
      <span class=\"glyphicon glyphicon-pencil\"></span>
      </button></div>
      <div class=\"controls email-entry__controls\" aria-hidden=\"true\">
            <div class='resend-confirmation'>
              #{resend_form}
            </div>
            <div class='delete'>
              <button type='button' class='account-security__delete-button'>Remove</button>
            </div>
            <div class=\"searchable-toggle\">
              <label><input type=\"checkbox\" class='searchable' #{searchable_checked}> #{I18n.t :"legacy.users.edit.searchable"}</label>
            </div>
          </div>
          <i class=\"spinner fa fa-spinner fa-spin fa-lg\" style=\"display:none\"></i>
            "
    else
      "</div>"
    end

    (
      <<-SNIPPET
        <div class="email-entry editable-click #{'verified' if is_verified}" data-id="#{id}">
          <div class="email-entry__header">
            <div class="email-entry__value">
              <span class="value">#{value}</span>
              #{unconfirmed_link}
            </div>
              #{toggle_content}
         
      
        </div>
      SNIPPET
    ).html_safe
  end

end
