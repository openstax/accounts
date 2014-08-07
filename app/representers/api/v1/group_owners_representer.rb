require 'representable/json/collection'

module Api::V1
  module GroupOwnersRepresenter
    include Representable::JSON::Collection

    items class: GroupOwner, decorator: GroupOwnerRepresenter
  end
end
