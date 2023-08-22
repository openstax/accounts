module Api::V1
  class ApplicationUserApplicationRepresenter < Roar::Decorator
    include Roar::JSON

    property :id,
             type: Integer,
             readable: true,
             writeable: false,
             getter: ->(*) { application.id },
             schema_info: {
               required: true,
               description: "The primary key of this Application"
             }

    property :name,
             type: String,
             readable: true,
             writeable: false,
             getter: ->(*) { application.name },
             schema_info: {
               required: true,
               description: "The name of this Application"
             }

    collection :roles,
      type: String,
      readable: true,
      writeable: false,
      schema_info: {
        required: true,
        description: "The User's roles in this application"
      }
  end
end
