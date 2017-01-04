module Dev
  class CreateUser

    lev_routine

    protected

    def user_params(inputs)
      if inputs[:username].nil? || inputs[:ensure_no_errors]
        loop do
          break if !inputs[:username].nil? && User.where(username: inputs[:username]).none?
          inputs[:username] = "#{inputs[:username] || 'user'}#{rand(1000000)}"
        end
      end

      ActionController::Parameters.new(inputs.except(:ensure_no_errors))
                                  .permit(:first_name, :last_name, :username)
                                  .merge(state: :activated)
    end

    def exec(inputs={})
      outputs[:user] = User.create(user_params(inputs))

      transfer_errors_from(outputs[:user], {type: :verbatim})
    end

  end
end
