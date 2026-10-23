require_relative 'newflow_request_phase'

class Googlenewflow < OmniAuth::Strategies::GoogleOauth2
  include NewflowRequestPhase

  option :path_prefix, '/i/auth'
  option :name, 'googlenewflow'
end
