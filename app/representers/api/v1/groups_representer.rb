require 'representable/json/collection'

module Api::V1
  module GroupsRepresenter
    include Representable::JSON::Collection

    items class: Group, decorator: GroupRepresenter
  end
end
