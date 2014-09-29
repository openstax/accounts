require 'representable/json/collection'

module Api::V1
  module GroupMembersRepresenter
    include Representable::JSON::Collection

    items class: GroupMember, decorator: GroupMemberRepresenter
  end
end
