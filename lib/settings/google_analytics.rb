module Settings
  module GoogleAnalytics

    class << self

      def send_google_analytics
        Settings::Db.store.send_google_analytics
      end

    end

  end
end
