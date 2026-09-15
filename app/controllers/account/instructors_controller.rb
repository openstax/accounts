module Account
  # Instructor-name search for the student account page's "who teaches your
  # class?" autocomplete. Only ever returns a verified instructor's display
  # name + school — no email, no other profile data. See User#verified_instructors_matching.
  class InstructorsController < Newflow::BaseController
    MAX_SEARCHES_PER_PERIOD = 30
    RATE_LIMIT_PERIOD = 1.minute

    before_action :require_authentication_json!
    before_action :enforce_search_rate_limit!

    def index
      instructors = User.verified_instructors_matching(params[:q]).includes(:school)

      render json: instructors.map { |instructor|
        { id: instructor.id, name: instructor.name, school: instructor.school&.name }
      }
    end

    private

    def require_authentication_json!
      return if signed_in?

      render json: { error: 'authentication_required' }, status: :unauthorized
    end

    # There's no app-wide rate-limit middleware (no Rack::Attack) to hook
    # into yet, so this is a small self-contained, best-effort sliding
    # window per user. It's a plain read+write (not atomic under heavy
    # concurrency) and is a no-op under the :null_store cache (as configured
    # in test) — good enough for a low-value autocomplete endpoint like this.
    def enforce_search_rate_limit!
      return unless current_user

      cache_key = "account_instructor_search:#{current_user.id}"
      count = Rails.cache.read(cache_key).to_i + 1
      Rails.cache.write(cache_key, count, expires_in: RATE_LIMIT_PERIOD)

      render(json: { error: 'rate_limited' }, status: :too_many_requests) if count > MAX_SEARCHES_PER_PERIOD
    end
  end
end
