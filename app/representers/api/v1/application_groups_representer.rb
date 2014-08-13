require 'representable/json/collection'

module Api::V1
  module ApplicationGroupsRepresenter
    include Representable::JSON::Collection

    items class: ApplicationGroup, decorator: ApplicationGroupRepresenter
  end
end
