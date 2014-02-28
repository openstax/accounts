class Api::V1::UsersController < Api::V1::OauthBasedApiController

  include OSU::Roar

  doorkeeper_for :all

  resource_description do
    api_versions "v1"
    short_description 'TBD'
    description <<-EOS
      TBD
    EOS
  end

  api :GET, '/users/:id', 'Gets the specified User'
  description <<-EOS
    #{json_schema(Api::V1::UserRepresenter, include: :readable)}            
  EOS
  def show
    debugger
    rest_get(User, params[:id])
  end

  def search

  end

end