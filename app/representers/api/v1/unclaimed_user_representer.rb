module Api::V1
  class UnclaimedUserRepresenter < Roar::Decorator
    include Roar::Representer::JSON

    property :id,
             type: Integer,
             readable: true,
             writeable: false

  end
end
