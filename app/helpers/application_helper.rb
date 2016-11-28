module ApplicationHelper

  include AlertHelper

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
    @page_title.sub!(SITE_NAME,"").strip! if @page_title.include?(SITE_NAME) && options[:take_out_site_name]

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

  def is_real_production_site?
    request.host == 'accounts.openstax.org'
  end

  def translate_error(code:, force: false)
    return unless @handler_result.try(:errors)

    error = @handler_result.errors.select{|error| error.code == code}.first

    return if error.nil?
    return if error.message.present? && !force

    # use a block for the error message so we avoid unnecesarry i18n translation
    error.message = yield
  end

end
