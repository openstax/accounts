class OsWebString < String
  def came_from_osweb?
    openstax_url = Rails.application.secrets.openstax_url
    self.include?(openstax_url)
  end
end
