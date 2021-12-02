require 'render_anywhere'

class ErrorPageBuilder
  include RenderAnywhere

  attr_reader :view, :message, :code

  def initialize(view:, message:, code:)
    @view = view
    @message = message
    @code = code
  end

  def build
    render template: 'errors/static',
           layout: 'static_error',
           locals: { view: view, message: message, code: code }
  end
end
