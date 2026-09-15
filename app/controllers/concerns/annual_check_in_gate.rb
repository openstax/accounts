# Gates Accounts-only landing surfaces (the account section, the newflow
# profile page) behind the annual instructor check-in interstitial.
#
# Deliberately narrow: only ever wired into controllers/actions that are
# purely Accounts-owned pages a signed-in user browses to directly. Must
# NEVER be added to OAuth/Doorkeeper controllers or LMS/product-driven
# login paths (Tutor, Assignable) -- those flows are not gated, by design.
module AnnualCheckInGate
  extend ActiveSupport::Concern

  CHECK_IN_RETURN_KEY = :check_in_return_to

  private

  # Only ever interposes on a plain GET page view. Never fires for
  # non-GET or XHR requests, and skips entirely if the check-in page
  # itself (or the current user) isn't a fit -- so it cannot loop.
  def redirect_to_check_in_if_due
    return unless request.get?
    return if request.xhr?
    return unless signed_in?
    return unless current_user.annual_check_in_due?

    store_url(key: AnnualCheckInGate::CHECK_IN_RETURN_KEY)
    redirect_to account_check_in_path
  end

  # Sends the user back to wherever the gate intercepted them, falling
  # back to a sensible Accounts page when nothing was stored.
  def redirect_to_check_in_destination(default:)
    url = stored_url(key: AnnualCheckInGate::CHECK_IN_RETURN_KEY)
    delete_stored_url(key: AnnualCheckInGate::CHECK_IN_RETURN_KEY)
    redirect_to(url.presence || default)
  end
end
