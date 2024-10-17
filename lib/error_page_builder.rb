class ErrorPageBuilder
  attr_reader :view, :message, :code

  def initialize(view:, message:, code:)
    @view = view
    @message = message
    @code = code
  end

  def build
    ApplicationController.renderer.render(
      template: 'errors/static',
      layout: 'static_error',
      locals: { view: view, message: message, code: code }
    )
  end
end
