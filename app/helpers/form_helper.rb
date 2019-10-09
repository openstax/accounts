module FormHelper

  class One
    def initialize(f:, limit_to: nil, context:, errors: nil, params: nil, error_field_classes: "error")
      @f = f
      @limit_to = limit_to
      @context = context
      @errors = errors
      @params = params
      @error_field_classes = error_field_classes
    end

    def c
      @context
    end

    def wrapper_div(name:, except: nil, only: nil, class_name: '', &block)
      return if excluded?(except: except, only: only)
      errors_div = get_errors_div(name: name)
      c.content_tag :div, class: "form-group #{class_name} #{'has-error' if errors_div.present?}" do
        content = c.capture(&block)
        errors_div.present? ? content + errors_div : content
      end
    end

    def text_field(name:, label: nil, value: nil, type: nil, autofocus: false, except: nil, only: nil)
      return if excluded?(except: except, only: only)

      errors_div = get_errors_div(name: name)

      label ||= ".#{name}"
      c.content_tag :div, class: "form-group #{'has-error' if errors_div.present?}" do
        input = @f.text_field name, placeholder: c.t(label),
                                    value: value,
                                    type: type,
                                    class: "form-control wide",
                                    data: data(only: only, except: except),
                                    autofocus: autofocus

        "#{input}\n#{errors_div}".html_safe
      end
    end

    def select(name:, options:, except: nil, only: nil, autofocus: nil)
      return if excluded?(except: except, only: only)

      errors_div = get_errors_div(name: name)

      html_options = {data: data(only: only, except: except)}
      html_options[:autofocus] = autofocus if !autofocus.nil?

      c.content_tag :div, class: "form-group #{'has-error' if errors_div.present?}" do
        "#{@f.select name, options, {}, html_options}#{errors_div}".html_safe
      end
    end

    def get_params_value(name)
      @params.try(:[], @f.object_name).try(:[], name)
    end

    def excluded?(except:, only:)
      return false if @limit_to == :any

      if only.present? && except.present?
        raise "Can only set one of `except` or `only`"
      elsif except.present?
        true if [except].flatten.compact.include?(@limit_to)
      elsif only.present?
        true if ![only].flatten.compact.include?(@limit_to)
      end
    end

    def data(only:, except:)
      {only: only, except: except}.delete_if{|k,v| v.nil?}
    end

    def get_errors_div(name:)
      field_errors = @errors.present? ?
                       @errors.select{|error| error.offending_inputs == [@f.object_name, name]} :
                      []

      return "" if field_errors.empty?

      c.content_tag(:div, class: "errors", role: "alert") do
        error_divs = field_errors.map do |field_error|
          c.content_tag(:div, class: @error_field_classes) { field_error.translate.html_safe }
        end
        error_divs.join.html_safe
      end
    end

  end

  class NewFlow
    def initialize(f:, header: nil, limit_to: nil, context:, errors: nil, params: nil, error_field_classes: "error")
      @f = f
      @header = header
      @limit_to = limit_to
      @context = context
      @errors = errors
      @params = params
      @error_field_classes = error_field_classes
    end

    def c
      @context
    end

    def wrapper_div(name:, except: nil, only: nil, class_name: '', &block)
      return if excluded?(except: except, only: only)
      errors_div = get_errors_div(name: name)
      c.content_tag :div, class: "form-group #{class_name} #{'has-error' if errors_div.present?}" do
        content = c.capture(&block)
        errors_div.present? ? content + errors_div : content
      end
    end

    def text_field(name:, placeholder:, value: nil, type: nil, autofocus: false, except: nil, only: nil)
      return if excluded?(except: except, only: only)

      errors_div = get_errors_div(name: name)

      c.content_tag :div, class: "form-group #{'has-error' if errors_div.present?}" do
        input = @f.text_field name, placeholder: placeholder,
                                    value: value,
                                    type: type,
                                    class: "form-control wide",
                                    data: data(only: only, except: except),
                                    autofocus: autofocus

        "#{input}\n#{errors_div}".html_safe
      end
    end

    def select(name:, options:, except: nil, only: nil, autofocus: nil)
      return if excluded?(except: except, only: only)

      errors_div = get_errors_div(name: name)

      html_options = {data: data(only: only, except: except)}
      html_options[:autofocus] = autofocus if !autofocus.nil?

      c.content_tag :div, class: "form-group #{'has-error' if errors_div.present?}" do
        "#{@f.select name, options, {}, html_options}#{errors_div}".html_safe
      end
    end

    def get_params_value(name)
      @params.try(:[], @f.object_name).try(:[], name)
    end

    def excluded?(except:, only:)
      return false if @limit_to == :any

      if only.present? && except.present?
        raise "Can only set one of `except` or `only`"
      elsif except.present?
        true if [except].flatten.compact.include?(@limit_to)
      elsif only.present?
        true if ![only].flatten.compact.include?(@limit_to)
      end
    end

    def data(only:, except:)
      {only: only, except: except}.delete_if{|k,v| v.nil?}
    end

    def get_errors_div(name:)
      field_errors = @errors.present? ?
                       @errors.select{|error| error.offending_inputs == [@f.object_name, name]} :
                      []

      return "" if field_errors.empty?

      c.content_tag(:div, class: "errors", role: "alert") do
        error_divs = field_errors.map do |field_error|
          c.content_tag(:div, class: @error_field_classes) { field_error.translate.html_safe }
        end
        error_divs.join.html_safe
      end
    end

  end

end
