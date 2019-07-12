ActionController::Base.class_exec do
  include UserSessionManagement
  include ApplicationHelper

  helper OSU::OsuHelper, ApplicationHelper, UserSessionManagement
end
