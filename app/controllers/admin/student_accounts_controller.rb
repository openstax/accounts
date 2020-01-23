require 'date'

module Admin
    class StudentAccountsController < BaseController
      layout 'admin'
  
      def actions
      end
  
      def get_number_of_accounts
        days_num = get_number_of_days
        accounts_num = query(days_num)
        flash[:notice] = "The number of student acccounts created since July 1 is " + accounts_num.to_s
        redirect_to actions_admin_student_accounts_path
      end

      def get_number_of_days
        # number of days since July 1
        today = Date.new
        year = today.year
        month = today.month
        if month < 6
            year = year - 1
        end
        #July is a keyword, so using month7
        month7 = Date.parse year.inspect + "-07-01"
        return (month7...today).count
      end

      def query(days_num)
        role_type = :student
        user_ids = User.where(role: role_type)
        return SecurityLog.where(event_type: :sign_up_successful, user_id: user_ids).where('created_at > ?', days_num.days.ago).count
      end
  
    end
  end