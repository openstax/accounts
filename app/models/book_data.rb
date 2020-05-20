class BookData < ActiveRecord::Base
  CACHE_DURATION = 1.day

  scope(
    :latest, -> {
      order(:created_at).last
    }
  )

  def latest_titles
    Rails.cache.fetch("#{cache_key_with_version}/latest_titles", expires_in: CACHE_DURATION) do
      # https://guides.rubyonrails.org/caching_with_rails.html#low-level-caching
      # Competitor::API.find_price(id)

      # latest()

      FetchBookData.titles
    end
  end
end
