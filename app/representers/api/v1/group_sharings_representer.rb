require 'representable/json/collection'

module Api::V1
  module GroupSharingsRepresenter
    include Representable::JSON::Collection

    items class: GroupSharing, decorator: GroupSharingRepresenter
  end
end
