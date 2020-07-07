module SheeridAPI
  class NullResponse < SheeridAPI::Base
    include Singleton

    def success?
      false
    end
  end
end
