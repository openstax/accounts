require_relative 'newflow_request_phase'

class Facebooknewflow < OmniAuth::Strategies::Facebook
  include NewflowRequestPhase

  option :path_prefix, '/i/auth'
  option :name, 'facebooknewflow'
end
