require 'representable/json/collection'

module Api::V1
  module ApplicationUsersRepresenter
    include Representable::JSON::Collection

    items class: ApplicationUser, decorator: ApplicationUserRepresenter
  end
end
