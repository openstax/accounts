module Newflow::LoginSignupHelper
  def is_osweb_user?(url)
    url.present? && url.include?(Rails.application.secrets.openstax_url)
  end
end
