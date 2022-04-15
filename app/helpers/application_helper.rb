module ApplicationHelper

  include AlertHelper

  def contact_us_link
    link_to(
      I18n.t(:"login_signup_form.contact_us"),
      salesforce_knowledge_base_url,
      target: '_blank',
      data: {
        # Google Analytics
        'ga-category': 'Login',
        'ga-action': 'Click',
        'ga-label': 'Contact Us'
      }
    ).html_safe
  end

  def logo_url
    Rails.application.secrets.openstax_url
  end

  def extract_params(url)
    return {} if url.blank?
    Addressable::URI.parse(url).query_values.to_h.with_indifferent_access
  end

  def prevent_caching
    response.headers["Cache-Control"] = "no-cache, no-store"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
  end

  def unless_errors(options={}, &block)
    errors = @handler_result.errors.each do |error|
      add_local_error_alert now: true, content: error.translate
    end

   @handler_result.errors.any? ?
     js_refresh_alerts(options) :
     js_refresh_alerts(options) + capture(&block).html_safe
  end

  def js_refresh_alerts(options={})
    options[:alerts_html_id] ||= 'local-alerts'
    options[:alerts_partial] ||= 'shared/local_alerts'
    options[:trigger] ||= 'alerts-updated'

    "$('##{options[:alerts_html_id]}').html('#{ j(render options[:alerts_partial]) }').trigger('#{options[:trigger]}');".html_safe
  end

  def alert_tag(messages)
    attention_tag(messages, :alert)
  end

  def notice_tag(messages)
    attention_tag(messages, :notice)
  end

  def attention_tag(messages, type)
    return if messages.blank? || messages.empty?
    messages = [messages].flatten

    alert_class = type == :alert ? "alert-danger" : "alert-info"

    content_tag :div, class: "alert #{alert_class}", role: "alert" do
      messages.size == 1 ?
       messages.first.html_safe :
        ("<ul>"+messages.collect{|a| "<li>#{a}</li>"}.join("")+"</ul>").html_safe
    end
  end

  def page_heading(heading_text, options={})
    options[:take_out_site_name] = true if options[:take_out_site_name].nil?
    options[:sub_heading_text] ||= ""
    options[:title_text] ||= heading_text + (options[:sub_heading_text].blank? ?
                                             "" :
                                             " [#{options[:sub_heading_text]}]")
    options[:center] ||= false

    @page_title = options[:title_text]
    @page_title.sub!('OpenStax Accounts','').strip! if @page_title.include?('OpenStax Accounts') && options[:take_out_site_name]

    return if heading_text.blank?

    content_for :page_heading do
      render(:partial => 'shared/page_heading',
             :locals => {:heading_text => heading_text,
                         :sub_heading_text => options[:sub_heading_text],
                         :center => options[:center]})
    end

  end

  def collect_errors
    alert_messages = []
    handler_errors.each do |error|
      alert_messages.push error.translate
    end

    (request.env['errors'] || []).each do |error|
      alert_messages.push error.translate
    end

    alert_messages.push(flash[:alert]) if flash[:alert]

    notice_messages = []
    notice_messages.push(flash[:notice]) if flash[:notice]

    alert_messages.collect{|msg|
      msg.gsub("contact support", mail_to("info@openstax.org", "contact support"))
        .html_safe
    }
    errors = {}
    errors[:alerts] = alert_messages if alert_messages.any?
    errors[:notices] = notice_messages if notice_messages.any?
    errors
  end

  def standard_field(options={})
    %i{type form name}.each{ |key| raise IllegalArgument, "Must specify a :#{key}" if !options[key] }

    options[:options] ||= {}
    hide = options[:options].delete(:hide)

    options[:options][:class] = "#{options[:options][:class]} form-control".strip
    options[:options][:style] = [options[:options][:style]].compact.join('; ')

    content_tag :div, class: 'form-group', style: "#{'display: none' if hide}" do
      output = []
      if options[:label]
        output << content_tag(:label, for: "#{options[:form].object_name}_#{options[:name]}") do
                    options[:label]
                  end
      end
      output <<
        case options[:type]
        when :text_field
          options[:form].text_field(options[:name], options[:options])
        when :password_field
          options[:form].password_field(options[:name], options[:options])
        when :hidden_field
          options[:form].hidden_field(options[:name], options[:options])
        when :email_field
          options[:form].email_field(options[:name], options[:options])
        else
          raise IllegalArgument, "Unknown field type #{options[:type]}"
        end

      output.reduce(:+)
    end
  end

  def translate_error(code:, force: false)
    return unless @handler_result.try(:errors)

    error = @handler_result.errors.select{|error| error.code == code}.first

    return if error.nil?
    return if error.message.present? && !force

    # use a block for the error message so we avoid unnecessary i18n translation
    error.message = yield
  end

  def ox_card(classes: "", heading: "", banners: nil, &block)
    @hide_layout_errors = true

    content_tag :div, class: "ox-card #{classes}" do

      danger_alerts = if flash[:alert].present?
        content_tag :div, class: "top-level-alerts danger" do
          alert_tag(flash[:alert])
        end
      end

      info_alerts = if flash[:notice].present?
        content_tag :div, class: "top-level-alerts info" do
          notice_tag(flash[:notice])
        end
      end

      banners ||= []
      banners_divs = banners.map do |banner|
        content_tag :div, class: "top-level-alerts info" do
          notice_tag(banner.message)
        end
      end.join("\n")

      heading_div = if heading.present?
        content_tag(:h1, class: "title") { heading }
      end

      body = capture(&block)

      "#{danger_alerts}\n#{info_alerts}\n#{banners_divs}\n#{heading_div}\n#{body}".html_safe
    end
  end

  def all_errors
    (@errors || []) + (@handler_result.try(:errors) || [])
  end

   ###########
  # NEW FLOW  #
   ###########

  def login_signup_card(classes: "", header: "", current_step: nil, show_exit_icon: false, &block)
    @hide_layout_errors = true

    content_tag :div, class: "#{classes}" do
      step_counter = if current_step.present?
        content_tag(:div, class:  'step-counter') {
          content_tag(:div) {
            content_tag(:span) {
              current_step
            }
          }
        }
      end

      exit_icon = if show_exit_icon
        content_tag(:div, id: 'exit-icon') {
          content_tag(:a, href: exit_accounts_path) {
            content_tag(:i, class: 'fa fa-times') { }
          }
        }
      end

      header = if header.present?
        content_tag(:header, class: "page-header") { header }
      end

      body = capture(&block)

      "#{step_counter}\n#{exit_icon}\n#{header}\n#{body}".html_safe
    end
  end

  # When current user wants to change their password,
  # but hasn't logged in in a while, we ask them to re-authenticate.
  # So we use this function to pre-populate their email field in the login form.
  def current_users_resetting_password_email
    !current_user.is_anonymous? && EmailAddress.verified.where(user: current_user).first.try(:value)
  end

end
