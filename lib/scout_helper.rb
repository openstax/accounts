module ScoutHelper

  def self.ignore!(fraction=1.0)
    ScoutApm::RequestManager.lookup.ignore_request! if (rand <= fraction)
  end

end
