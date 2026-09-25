module Settings
  module SheerId

    # Not a secret, and not admin-editable: this id ships inside the iframe URL
    # that every visitor's browser loads, so it belongs in the repo where it is
    # reviewable. Override per environment to point at a different program.
    DEFAULT_PROGRAM_ID = '6a7c5eb82050c35ab0e1f676'.freeze

    # A program verification URL is the one that speaks the iframe protocol our
    # `newflow/sheerid_iframe.js` listens to. A hosted offers.sheerid.com page
    # renders the same form but never reports its height, which is what left the
    # frame stuck at a hardcoded size.
    ORIGIN = 'https://services.sheerid.com'.freeze

    class << self

      def program_id
        ENV.fetch('SHEERID_PROGRAM_ID', DEFAULT_PROGRAM_ID)
      end

      def origin
        ORIGIN
      end

      def verification_url
        "#{origin}/verify/#{program_id}/"
      end

    end

  end
end
