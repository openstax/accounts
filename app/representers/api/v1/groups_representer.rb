require 'representable/json/collection'

module Api::V1
  class GroupsRepresenter < Roar::Decorator
    include Representable::JSON::Collection

    items class: Group, decorator: GroupRepresenter

    def to_hash(options = {})
      # Avoid N+1 load on groups
      ActiveRecord::Associations::Preloader.new(
        records: represented.to_a,
        associations: [
          { group_members: { user: { application_users: :application } } },
          { group_owners: { user: { application_users: :application } } },
          :member_group_nestings
        ]
      ).call

      super(options)
    end
  end
end
