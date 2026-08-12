require 'representable/json/collection'

module Api::V1
  class ApplicationUsersRepresenter < Roar::Decorator
    include Representable::JSON::Collection

    items class: ApplicationUser, decorator: ApplicationUserRepresenter

    def to_hash(options = {})
      # Avoid N+1 load on application_users.user
      ActiveRecord::Associations::Preloader.new(
        records: represented.to_a,
        associations: { user: { application_users: :application } }
      ).call

      super(options)
    end
  end
end
