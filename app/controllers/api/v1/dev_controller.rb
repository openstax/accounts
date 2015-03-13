class Api::V1::DevController < OpenStax::Api::V1::ApiController

  before_filter Proc.new{ 
    raise SecurityTransgression if Rails.env.production?
  }

  include FakeExceptionHelper

  def raise_exception
    raise_fake_exception(params[:type])
  end

end