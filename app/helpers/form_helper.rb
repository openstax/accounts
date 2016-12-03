module FormHelper

  class One
    def initialize(f:, limit_to: nil, context:, errors: nil, error_field_classes: "error")
      @f = f
      @limit_to = limit_to
      @context = context
      @errors = errors
      @error_field_classes = error_field_classes
    end

    def c
      @context
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
                                    autofocus: autofocus

        "#{input}\n#{errors_div}".html_safe
      end
    end

    def select(name:, options:, except: nil, only: nil)
      return if excluded?(except: except, only: only)

      errors_div = get_errors_div(name: name)

      c.content_tag :div, class: "form-group #{'has-error' if errors_div.present?}" do
        "#{@f.select name, options}#{errors_div}".html_safe
      end
    end

    def excluded?(except:, only:)
      if only.present? && except.present?
        raise "Can only set one of `except` or `only`"
      elsif except.present?
        true if [except].flatten.compact.include?(@limit_to)
      elsif only.present?
        true if ![only].flatten.compact.include?(@limit_to)
      end
    end

    def get_errors_div(name:)
      field_errors = @errors.present? ?
                       @errors.select{|error| error.offending_inputs == [@f.object_name, name]} :
                      []

      return "" if field_errors.empty?

      c.content_tag :div, class: "errors" do
        error_divs = field_errors.map do |field_error|
          c.content_tag(:div, class: @error_field_classes) { field_error.translate.html_safe }
        end
        error_divs.join.html_safe
      end
    end

  end

end
