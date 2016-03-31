module Dev
  class CreateUser

    lev_routine

    protected

    def exec(inputs={})

      username = inputs[:username]

      if username.nil? || inputs[:ensure_no_errors]
        loop do
          break if !username.nil? && User.where(username: username).none?
          username = "#{inputs[:username] || 'user'}#{rand(1000000)}"
        end
      end

      outputs[:user] = User.create do |user|
        user.first_name = inputs[:first_name]
        user.last_name = inputs[:last_name]
        user.username = username
      end

      transfer_errors_from(outputs[:user], {type: :verbatim})
    end

  end
end
