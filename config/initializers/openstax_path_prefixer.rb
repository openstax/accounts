OpenStax::PathPrefixer.configure do |config|
  config.prefix = "accounts"
  config.prefix_assets = Rails.env.production?
end
