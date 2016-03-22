module ProfileHelper

  def way_to_login(provider:, user_authentications: nil, has_authentication: nil)
    if has_authentication.nil?
      if user_authentications.nil?
        raise "At least one of user_authentications or has_authentication must be set"
      end

      has_authentication = user_authentications.any?{|auth| auth.provider == provider}
    end

    icon_class, display_name, edit_possible, trash_possible =
      case provider
      when 'identity' then ['key', 'Simple Password', true, true]
      else [provider, provider.capitalize, false, true]
      end

    change_icons = [
      ('glyphicon-pencil'  if has_authentication && edit_possible),
      ('glyphicon-trash' if has_authentication && trash_possible),
      ('glyphicon-plus'  if !has_authentication)
    ].compact

    icon_tags = change_icons.collect do |change_icon|
      "<span class='glyphicon #{change_icon} mod'></span>"
    end.join("")

    snippet = <<-SNIPPET
      <span class="fa-stack fa-lg">
        <i class="fa fa-square fa-stack-2x #{provider}-bkg#{' dim' if !has_authentication}"></i>
        <i class="fa fa-#{icon_class} fa-stack-1x fa-inverse"></i>
      </span>
      <span class="#{'dim' if !has_authentication}">#{display_name}</span>
      <span class="mod-holder">
        #{icon_tags}
      </span>
    SNIPPET

    "<div class='authentication hoverable'>#{snippet}</div>".html_safe
  end

  def email_entry(value:, id:, is_verified:, is_searchable:)
    (
      <<-SNIPPET
        <div class="email">
          #{value}
          <span class="mod-holder"><span class="glyphicon glyphicon-trash mod"></span></span>
          <div class="properties">
            #{#TODO add a property row with 'Verify this address now!' link if unverified
            }
            <input type="checkbox" data-id="#{id}" #{'checked="IS_SEARCHABLE"' if is_searchable}> Searchable
            <i class="fa fa-info-circle" data-toggle="tooltip" data-placement="right" title="Check the Searchable box if you want other OpenStax users to find you using this email address."></i>
          </div>
        </div>
      SNIPPET
    ).html_safe
  end

end
