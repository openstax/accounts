require 'representable/json/collection'

module Api::V1
  module UsersRepresenter
    include Representable::JSON::Collection

    items extend: UserRepresenter, class: User
  end
end
