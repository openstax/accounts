require 'representable/json/collection'

module Api::V1
  module ApplicationUsersRepresenter
    include Representable::JSON::Collection

    items extend: ApplicationUserRepresenter, class: ApplicationUser
  end
end
