require 'representable/json/collection'

module Api::V1
  class ApplicationGroupsRepresenter < Roar::Decorator
    include Representable::JSON::Collection

    items class: ApplicationGroup, decorator: ApplicationGroupRepresenter

    def to_hash(options = {})
      # Avoid N+1 load on application_groups.group
      ActiveRecord::Associations::Preloader.new.preload represented, group: [
        { group_members: :user },
        { group_owners: :user },
        :member_group_nestings
      ]

      super(options)
    end
  end
end
