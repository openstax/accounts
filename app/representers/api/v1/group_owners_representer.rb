require 'representable/json/collection'

module Api::V1
  class GroupOwnersRepresenter < Roar::Decorator
    include Representable::JSON::Collection

    items class: GroupOwner, decorator: GroupOwnerRepresenter

    def to_hash(options = {})
      # Avoid N+1 load on group_members.group
      ActiveRecord::Associations::Preloader.new.preload(
        represented.to_a, group: [
          { group_members: { user: { application_users: :application } } },
          { group_owners: { user: { application_users: :application } } },
          :member_group_nestings
        ]
      )

      super(options)
    end
  end
end
