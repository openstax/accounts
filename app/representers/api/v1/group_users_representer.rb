require 'representable/json/collection'

module Api::V1
  module GroupUsersRepresenter
    include Representable::JSON::Collection

    items class: GroupUser, decorator: GroupUserRepresenter
  end
end
