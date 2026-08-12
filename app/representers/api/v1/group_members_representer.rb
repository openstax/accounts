require 'representable/json/collection'

module Api::V1
  class GroupMembersRepresenter < Roar::Decorator
    include Representable::JSON::Collection

    items class: GroupMember, decorator: GroupMemberRepresenter

    def to_hash(options = {})
      # Avoid N+1 load on group_members.group
      ActiveRecord::Associations::Preloader.new(
        records: represented.to_a,
        associations: {
          group: [
            { group_members: { user: { application_users: :application } } },
            { group_owners: { user: { application_users: :application } } },
            :member_group_nestings
          ]
        }
      ).call

      super(options)
    end
  end
end
