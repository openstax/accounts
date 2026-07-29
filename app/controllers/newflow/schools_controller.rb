module Newflow
  class SchoolsController < BaseController

    skip_before_action :set_active_banners

    def index
      schools = School.search(params[:q])
      render json: schools.map { |school|
        {
          id: school.id,
          name: school.name,
          city: school.city,
          state: school.state,
          # Lets client-side JS conditionally show K-12-only questions (e.g. grade
          # band) right after a school is picked, without a second round trip.
          k12: school.user_school_type.in?([:k12_school, :high_school])
        }
      }
    end

  end
end
