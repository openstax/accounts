require 'representable/json/collection'

module Api::V1
  module GroupStaffsRepresenter
    include Representable::JSON::Collection

    items class: GroupStaff, decorator: GroupStaffRepresenter
  end
end
