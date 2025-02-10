require 'representable/json/collection'

module Api::V1
  class ApplicationUsersRepresenter < Roar::Decorator
    include Representable::JSON::Collection

    items class: ApplicationUser, decorator: ApplicationUserRepresenter

    def to_hash(options = {})
      # Avoid N+1 load on application_users.user
      ActiveRecord::Associations::Preloader.new.preload(
        represented.to_a, user: { application_users: :application }
      )

      super(options)
    end
  end
end
