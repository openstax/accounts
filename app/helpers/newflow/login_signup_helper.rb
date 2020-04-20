module Newflow
  module LoginSignupHelper
    def extract_params(url)
      return {} if url.blank?
      Addressable::URI.parse(url).query_values.to_h.with_indifferent_access
    end
  end
end
