module Dev
  class UsersCreate

    lev_handler

    paramify :create do
      attribute :first_name, type: String
      attribute :last_name, type: String
      attribute :username, type: String
      attribute :is_admin, type: boolean

      validates :username, presence: true
    end

    uses_routine Dev::CreateUser,
                 as: :create_user,
                 translations: { inputs: { scope: :create },
                                 outputs: { type: :verbatim } }

    uses_routine CreateIdentity,
                 translations: { inputs: { scope: :create },
                                 outputs: { type: :verbatim } }

    protected

    def authorized?
      !Rails.env.production?
    end

    def handle
      run(:create_user, create_params.as_hash(:first_name, :last_name, :username))
      outputs[:user].update_attribute(:is_administrator, create_params.is_admin)
      user = outputs[:user]
      run(CreateIdentity, user_id: user.id, password: 'password', password_confirmation: 'password')
      authentication = Authentication.create(uid: outputs[:identity].id.to_s,
                                             provider: 'identity',
                                             user_id: user.id)
      FinePrint::Contract.all.each do |contract|
        FinePrint.sign_contract(user, contract)
      end
    end

  end 
end
