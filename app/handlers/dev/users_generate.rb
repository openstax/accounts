module Dev
  class UsersGenerate
    lev_handler

    paramify :generate do
      attribute :count, type: Integer
      validates :count, numericality: { only_integer: true,
                                        greater_than_or_equal_to: 0 }
    end

    uses_routine Dev::CreateUser,
             translations: { inputs: { scope: :create },
                             outputs: { type: :verbatim } }

  protected

    def authorized?
      !Rails.env.production?
    end

    def handle
      generate_params.count.times do 
        run(Dev::CreateUser, {ensure_no_errors: true})
      end
    end

  end 
end
