module Admin
    class StudentAccountsController < BaseController
      layout 'admin'
  
      def actions
      end
  
      def get_number_of_accounts
        year = get_year
        num_of_accounts = query(year)
        flash[:notice] = "The number of student acccounts created since July 1 is #{num_of_accounts}"
        redirect_to actions_admin_student_accounts_path
      end

      def get_year
        # correct year for July 1
        today = DateTime.now
        year = today.year
        month = today.month
        if month < 7
            year = year - 1
        end
        return year
      end

      def query(year)
        role_type = :student
        user_ids = User.where(role: role_type)
        return SecurityLog.where(event_type: :sign_up_successful, user_id: user_ids).where('created_at >= ?', Date.parse(year.inspect + '-07-01')).count
      end
  
    end
  end