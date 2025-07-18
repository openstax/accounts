module NewflowFormHelper
  class Newflow
    def initialize(f:, header: nil, limit_to: nil, context:, params: nil, errors: nil)
      @f = f
      @header = header
      @limit_to = limit_to
      @context = context
      @params = params
      @errors = errors
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

    def text_field(name:,
                   placeholder:,
                   value: nil,
                   type: nil,
                   autofocus: false,
                   except: nil,
                   only: nil,
                   supplemental_class: nil,
                   readonly: false,
                   onkeyup: nil,
                   onkeydown: nil,
                   numberonly: false,
                   disabled: false,
                   described: nil,
                   required: false,
                   list: nil)
      return if excluded?(except: except, only: only)

      errors_div = get_errors_div(name: name)

      desired_class_name = "form-control wide #{'has-error' if errors_div.present?}"
      if supplemental_class.present?
        desired_class_name = "#{desired_class_name} #{supplemental_class}"
      end

      if numberonly
        input = (
        @f.number_field name,
                      placeholder: placeholder,
                      value: value,
                      type: type,
                      class: desired_class_name,
                      min: 0,
                      max: 2000,
                      data: data(only: only, except: except),
                      autofocus: autofocus,
                      readonly: readonly,
                      onkeyup: onkeyup,
                      onkeydown: onkeydown,
                      disabled: disabled,
                      'aria-required': required
        )
      else
        input = (
        @f.text_field name,
                      placeholder: placeholder,
                      value: value,
                      type: type,
                      class: desired_class_name,
                      data: data(only: only, except: except),
                      autofocus: autofocus,
                      readonly: readonly,
                      onkeyup: onkeyup,
                      onkeydown: onkeydown,
                      disabled: disabled,
                      list: list,
                      'aria-describedby': described,
                      'aria-required': required
        )
      end
      "#{input}\n#{errors_div}".html_safe
    end

    def select(name:, options:, except: nil, only: nil, autofocus: nil, multiple: false, custom_class: nil, disabled: false)
      return if excluded?(except: except, only: only)

      errors_div = get_errors_div(name: name)

      html_options = { data: data(only: only, except: except) }
      html_options[:autofocus] = autofocus if !autofocus.nil?
      html_options[:multiple] = multiple
      html_options[:class] = custom_class if custom_class
      html_options[:disabled] = disabled

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
      { only: only, except: except}.delete_if{|k,v| v.nil? }
    end

    def get_errors_div(name:)
      field_errors = @errors.present? ?
                       @errors.select{ |error| [error.offending_inputs].flatten.include?(name) } :
                      []

      return '' if field_errors.empty?

      c.content_tag(:div, class: "errors invalid-message") do
        # TODO: show multiple error messages per field when the pattern-library is fixed.
        error_divs = field_errors.map do |field_error|
          field_error.translate.html_safe
        end
        error_divs.join('<br>').html_safe
      end
    end
  end
end
