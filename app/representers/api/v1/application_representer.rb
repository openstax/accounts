module Api::V1
  class ApplicationRepresenter < Roar::Decorator
    include Roar::JSON

    property :id,
             type: Integer,
             readable: true,
             writeable: false,
             schema_info: {
               required: true,
               description: "The primary key of this Application"
             }

    property :name,
             type: String,
             readable: true,
             writeable: false,
             schema_info: {
               required: true,
               description: "The name of this Application"
             }

  end
end
