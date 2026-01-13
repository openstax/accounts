module Settings
  module Recaptcha

    class << self

      def disabled?
        Settings::Db.store.disable_recaptcha
      end

      def disabled=(bool)
        Settings::Db.store.disable_recaptcha = bool
      end

      def enabled?
        !disabled?
      end

    end

  end
end
