module ApplicationHelper

  include AlertHelper

  # rubocop:disable Rails/HelperInstanceVariable
  def contact_us_link
    link_to(
      I18n.t(:'login_signup_form.contact_us'),
      salesforce_knowledge_base_url,
      target: '_blank',
      data: {
        # Google Analytics
        'ga-category': 'Login',
        'ga-action': 'Click',
        'ga-label': 'Contact Us'
      }, rel: 'noopener'
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

  def profile_card(classes: "", heading: "", &block)
    @hide_layout_errors = true

    content_tag :div, class: "profile #{classes}" do

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

      header = if header.present?
                 content_tag(:header, class: "page-header") { header }
               end

      body = capture(&block)

      "#{danger_alerts}\n#{info_alerts}\n#{header}\n#{body}".html_safe
    end
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

      "#{step_counter}\n#{exit_icon}\n#{header}\n#{body}".html_safe # disa
    end
  end
  # rubocop:enable Rails/HelperInstanceVariable

  # When current user wants to change their password,
  # but hasn't logged in in a while, we ask them to re-authenticate.
  # So we use this function to pre-populate their email field in the login form.
  def current_users_resetting_password_email
    !current_user.is_anonymous? && EmailAddress.verified.where(user: current_user).first.try(:value)
  end

end
