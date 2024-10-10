class ErrorPageBuilder
  attr_reader :view, :message, :code

  class DummyRequest < OpenStruct
    def initialize
      super
      self.path_parameters ||= {}
    end

    def engine_script_name(_)
      ''
    end
  end

  def initialize(view:, message:, code:)
    @view = view
    @message = message
    @code = code
  end

  def build
    renderer = ApplicationController.new
    renderer.set_request! DummyRequest.new
    renderer.render_to_string(
      template: 'errors/static',
      layout: 'static_error',
      locals: { view: view, message: message, code: code }
    )
  end
end
