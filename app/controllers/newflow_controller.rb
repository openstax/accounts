class NewflowController < ApplicationController
    layout 'newflow_layout'
    skip_before_action :authenticate_user!

    def signin
    end

    def signup
    end
end
