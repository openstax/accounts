module FormHelper

  class One
    def initialize(f:, limit_to: nil, context:, errors: nil)
      @f = f
      @limit_to = limit_to
      @context = context
      @errors = errors
    end

    def c
      @context
    end

    def text_field(name:, label: nil, value: nil, type: nil, autofocus: false, except: nil, only: nil)
      if only.present? && except.present?
        raise "Can only set one of `except` or `only`"
      elsif except.present?
        return if [except].flatten.compact.include?(@limit_to)
      elsif only.present?
        return unless [only].flatten.compact.include?(@limit_to)
      end

      error = @errors.present? ?
              @errors.find{|error| error.offending_inputs == [@f.object_name, name]} :
              false

      # TODO actually show the error message

      label ||= ".#{name}"
      c.content_tag :div, class: "form-group #{'has-error' if error}" do
        @f.text_field name, placeholder: c.t(label),
                            value: value,
                            type: type,
                            class: "form-control wide",
                            autofocus: autofocus
      end
    end
  end

end
