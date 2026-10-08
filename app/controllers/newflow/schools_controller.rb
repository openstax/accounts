module Newflow
  class SchoolsController < BaseController

    skip_before_action :set_active_banners

    def index
      schools = School.search(params[:q])
      render json: schools.map { |school|
        { id: school.id, name: school.name, city: school.city, state: school.state }
      }
    end

  end
end
