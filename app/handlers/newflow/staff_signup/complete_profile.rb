module Newflow
  module StaffSignup
    class CompleteProfile

      OTHER = 'other'

      # Maps the radio button chosen on the "Tell us about your work" step to
      # a User#role enum value. We always store the literal chosen label (or
      # the free-text answer for "Other") in other_role_name so we don't lose
      # the more specific selection when two options collapse to one role
      # (e.g. "Department chair" and "LMS / IT administrator" both map to
      # 'administrator'). All of these roles already exist in
      # User::VALID_ROLES — no new role or migration needed.
      ROLE_OPTIONS = {
        'department_chair'       => { role: 'administrator', label: 'Department chair' },
        'librarian'              => { role: 'librarian', label: 'Librarian' },
        'curriculum_coordinator' => { role: 'designer', label: 'Curriculum coordinator' },
        'lms_it_administrator'   => { role: 'administrator', label: 'LMS / IT administrator' },
        'homeschool_educator'    => { role: 'homeschool', label: 'Homeschool educator' },
        OTHER                    => { role: 'other', label: nil }
      }.freeze

      lev_handler

      paramify :signup do
        attribute :school_name, type: String
        attribute :school_id, type: Integer
        attribute :staff_role, type: String
        attribute :other_role_name, type: String
        attribute :books_involved, type: Object
        attribute :num_learners_supported, type: String

        validates(
          :staff_role,
          inclusion: { in: ROLE_OPTIONS.keys }
        )
      end

      protected ###############

      attr_reader :user

      def setup
        @user = options[:user]
      end

      def authorized?
        @user && !@user.is_anonymous?
      end

      def handle
        check_params
        return if errors?

        num_learners = validated_num_learners_supported
        return if errors?

        selected_school = School.find_by(id: signup_params.school_id) if signup_params.school_id.present?
        if signup_params.school_name.present? || signup_params.school_id.present?
          user.school = selected_school
        end

        role_option = ROLE_OPTIONS.fetch(signup_params.staff_role)

        user.update!(
          role: role_option[:role],
          other_role_name: other_role_name(role_option),
          which_books: which_books,
          how_many_students: num_learners,
          self_reported_school: selected_school&.name || signup_params.school_name,
          is_profile_complete: true
        )

        transfer_errors_from(user, { type: :verbatim }, :fail_if_errors)

        SecurityLog.create!(
          user: user,
          event_type: :user_profile_complete,
          event_data: { staff_role: signup_params.staff_role, which_books: which_books }
        )

        CreateOrUpdateSalesforceLead.perform_later(user: user) if Settings::Salesforce.push_leads_enabled

        outputs.user = user
      end

      private #################

      def check_params
        if signup_params.staff_role == OTHER && signup_params.other_role_name.blank?
          param_error(:other_role_name, :other_must_be_entered)
        end

        if signup_params.school_name.blank? && signup_params.school_id.blank?
          param_error(:school_name, :school_name_must_be_entered)
        end
      end

      def validated_num_learners_supported
        value = signup_params.num_learners_supported

        if value.blank?
          param_error(:num_learners_supported, :num_learners_supported_must_be_entered)
          return nil
        end

        count = Integer(value, 10)
        if count.negative?
          param_error(:num_learners_supported, :num_learners_supported_must_be_entered)
          return nil
        end

        count
      rescue ArgumentError, TypeError
        param_error(:num_learners_supported, :num_learners_supported_must_be_entered)
        nil
      end

      def other_role_name(role_option)
        return signup_params.other_role_name.strip if signup_params.staff_role == OTHER

        role_option[:label]
      end

      def books_involved
        Array(signup_params.books_involved).reject(&:blank?)
      end

      def which_books
        return nil if books_involved.blank?

        books_involved.join(';')
      end

      def param_error(field, error_key)
        message = I18n.t(:"staff_details_form.#{error_key}")
        nonfatal_error(
          code: field,
          message: message,
          offending_inputs: field
        )
      end

    end
  end
end
