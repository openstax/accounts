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

    def text_field(name:, placeholder:, value: nil, type: nil, autofocus: false, except: nil, only: nil, readonly: false)
      return if excluded?(except: except, only: only)

      errors_div = get_errors_div(name: name)
      input = (
        @f.text_field name,
        placeholder: placeholder,
        value: value,
        type: type,
        class: "form-control wide #{'has-error' if errors_div.present?}",
        data: data(only: only, except: except),
        autofocus: autofocus,
        readonly: readonly
      )

      "#{input}\n#{errors_div}".html_safe
    end

    def select(name:, options:, except: nil, only: nil, autofocus: nil)
      return if excluded?(except: except, only: only)

      errors_div = get_errors_div(name: name)

      html_options = { data: data(only: only, except: except) }
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
      { only: only, except: except}.delete_if{|k,v| v.nil? }
    end

    def get_errors_div(name:)
      field_errors = @errors.present? ?
                       @errors.select{ |error| [error.offending_inputs].flatten.include?(name) } :
                      []

      return '' if field_errors.empty?

      c.content_tag(:div, class: "errors") do
        error_divs = field_errors.map do |field_error|
          c.content_tag(:div, class: 'invalid-message') { field_error.translate.html_safe }
        end
        error_divs.join.html_safe
      end
    end
  end
end
