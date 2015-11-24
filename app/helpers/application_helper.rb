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

  def attention_tag(messages, type, classes='')
    return if messages.blank? || messages.empty?
    messages = Array.new(messages).flatten
    
    div_class = type == :alert ? "ui-state-error" : "ui-state-highlight"
    icon_class = type == :alert ? "ui-icon-alert" : "ui-icon-info"
    
    content_tag :div, :class => "ui-widget #{classes}" do
      content_tag :div, :class => "#{div_class} ui-corner-all", 
                        :style => "margin: 10px 0px -5px; padding: 0 .7em;" do
        content_tag :p do
          content_tag(:span, "", :class => "ui-icon #{icon_class}",
                             :style => "float:left; margin-right: .3em;") +
          (type == :alert ? content_tag(:strong, "Alert: ") : "") +

          (messages.size == 1 ? 
           messages.first : 
           ("<ul>"+messages.collect{|a| "<li>"+a+"</li>"}.join("")+"</ul>").html_safe)
        end
      end
    end
  end

  def page_heading(heading_text, options={})
    options[:take_out_site_name] = true if options[:take_out_site_name].nil?
    options[:sub_heading_text] ||= ""
    options[:title_text] ||= heading_text + (options[:sub_heading_text].blank? ? 
                                             "" : 
                                             " [#{options[:sub_heading_text]}]")
    
    @page_title = options[:title_text]
    @page_title.sub!(SITE_NAME,"").strip! if @page_title.include?(SITE_NAME) && options[:take_out_site_name]
    
    return if heading_text.blank?
    
    content_for :page_heading do
      render(:partial => 'shared/page_heading', 
             :locals => {:heading_text => heading_text, 
                         :sub_heading_text => options[:sub_heading_text]})
    end
    
  end

  def standard_field(options={})

    raise IllegalArgument, "Must specify a :type" if !options[:type] 
    raise IllegalArgument, "Must specify a :form" if !options[:form] 
    raise IllegalArgument, "Must specify a :name" if !options[:name] 

    options[:options] ||= {}

    content_tag :div, class: 'form-field' do
      output = []
      if options[:label]
        output << content_tag(:label, class: 'form-label',
                              for: "#{options[:form].object_name}_#{options[:name]}") do
                  options[:label]
                end
      end
      output << content_tag(:div, class: 'form-input') do
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
      end
      output.reduce(:+)
    end
  end

end
