class Api::V1::ApiController < OpenStax::Api::V1::ApiController
  # `complete_signup_profile` redirects users who must still finish their profile
  # to the signup page. It is an HTML-only concern and must never run for a JSON
  # API. It fires whenever the request format resolves to :html. A browser
  # `fetch` sends `Accept: */*`, which Rails maps to :html. The redirect below
  # then becomes a bare 403, so a signed-in user who needs a profile looks
  # logged out.
  skip_before_action :complete_signup_profile, raise: false

  # JSON can't really redirect.
  # A redirect from a filter effectively means "deny access", so answer 403 --
  # but with a body that names the reason, not a blank response a caller cannot
  # tell apart from a network failure.
  def redirect_to(options = {}, response_status = {})
    render json: { status: 'forbidden' }, status: :forbidden
  end
end
