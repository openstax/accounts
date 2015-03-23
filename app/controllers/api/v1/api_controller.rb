class Api::V1::ApiController < OpenStax::Api::V1::ApiController
  skip_before_filter :authenticate_user!

  # JSON can't really redirect
  # Redirect from a filter effectively means "deny access"
  def redirect_to(options = {}, response_status = {})
    head :forbidden
  end
end
