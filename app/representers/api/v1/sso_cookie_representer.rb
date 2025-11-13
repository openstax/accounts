module Api::V1
  class SsoCookieRepresenter < Roar::Decorator
    include Roar::JSON

    property :name,
             type: String,
             readable: true,
             writeable: false

    property :uuid,
             type: String,
             readable: true,
             writeable: false
  end
end
