module ApplicationHelper

  include AuthenticateMethods
  include UserSessionManagement

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
          content_tag(:a, href: logout_path) {
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
end
