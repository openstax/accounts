module Settings
  module EmergencyBannerMessage

    class << self

      def emergency_banner_message
        Settings::Db.store.emergency_banner_message
      end

      def display_emergency_message
        Settings::Db.store.display_emergency_message
      end

    end

  end
end
