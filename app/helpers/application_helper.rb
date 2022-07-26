module ApplicationHelper

  include AuthenticateMethods
  include UserSessionManagement

  # To ease the transition to the shared signup controller
  # TODO: Remove when the new shared signup controller is added
  def signup_form_path(role:)
    if role == 'student'
      signup_student_path
    else
      educator_signup_path
    end
  end

  def change_signup_email_form_path
    if unverified_user.role == 'student'
      student_change_signup_email_form_path
    else
      educator_change_signup_email_form_path
    end
  end

  def verify_email_by_pin_path
    if unverified_user.role == 'student'
      student_verify_pin_path
    else
      educator_verify_pin_path
    end
  end
  # end TODO

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

  def page_heading(heading_text, options={})
    options[:take_out_site_name] = true if options[:take_out_site_name].nil?
    options[:sub_heading_text] ||= ""
    options[:title_text] ||= heading_text + (options[:sub_heading_text].blank? ?
                                             "" :
                                             " [#{options[:sub_heading_text]}]")
    options[:center] ||= false

    @page_title = options[:title_text]
    @page_title.sub!(SITE_NAME,"").strip! if @page_title.include?(SITE_NAME) && options[:take_out_site_name]

    return if heading_text.blank?

    content_for :page_heading do
      render(:partial => 'shared/page_heading',
             :locals => {:heading_text => heading_text,
                         :sub_heading_text => options[:sub_heading_text],
                         :center => options[:center]})
    end

  end

  def is_real_production_site?
    Rails.application.secrets.environment_name == 'production'
  end

  def translate_error(code:, force: false)
    return unless @handler_result.try(:errors)

    error = @handler_result.errors.select{|error| error.code == code}.first

    return if error.nil?
    return if error.message.present? && !force

    # use a block for the error message so we avoid unnecessary i18n translation
    error.message = yield
  end

  def profile_card(classes: "", heading: "", &block)
    @hide_layout_errors = true

    content_tag :div, class: "ox-card #{classes}" do

      danger_alerts = if flash[:alert].present?
        content_tag :div, class: "top-level-alerts danger" do
          flash[:alert]
        end
      end

      info_alerts = if flash[:notice].present?
        content_tag :div, class: "top-level-alerts info" do
          flash[:notice]
        end
      end

      heading_div = if heading.present?
        content_tag(:h1, class: "title") { heading }
      end

      body = capture(&block)

      "#{danger_alerts}\n#{info_alerts}\n#{heading_div}\n#{body}".html_safe
    end
  end

  def all_errors
    (@errors || []) + (@handler_result.try(:errors) || [])
  end

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
