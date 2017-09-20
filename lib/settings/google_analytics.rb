module Settings
  module GoogleAnalytics

    class << self

      def send_google_analytics
        Settings::Db.store.send_google_analytics
      end

      def google_analytics_code
        Settings::Db.store.google_analytics_code
      end

    end

  end
end
