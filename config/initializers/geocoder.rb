Geocoder.configure(
  api_key: ENV['GOOGLE_PLACES_API_KEY'],
  use_https: true,
  lookup: :google
)