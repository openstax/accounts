module Api::V1
  class ExternalIdRepresenter < Roar::Decorator
    include Roar::JSON

    property :user_id,
             type: Integer,
             readable: true,
             writeable: true

    property :external_id,
             type: String,
             readable: true,
             writeable: true

    property :role,
             type: String,
             readable: true,
             writeable: true
  end
end
