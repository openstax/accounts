module Settings
  module FeatureFlags
    class << self

      def any_newflow_feature_flags?
        student_feature_flag || educator_feature_flag
      end

      def student_feature_flag
        Settings::Db.store.student_feature_flag
      end

      def student_feature_flag=(bool)
        Settings::Db.store.student_feature_flag = bool
      end

      def educator_feature_flag
        Settings::Db.store.educator_feature_flag
      end

      def educator_feature_flag=(bool)
        Settings::Db.store.educator_feature_flag = bool
      end

      def expected_start_semester_enabled
        Settings::Db.store.expected_start_semester_enabled
      end

      def expected_start_semester_enabled=(bool)
        Settings::Db.store.expected_start_semester_enabled = bool
      end

    end
  end
end
