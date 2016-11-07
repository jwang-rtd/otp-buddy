module MapHelper

  # Create an array of map markers suitable for the Leaflet plugin.
  def create_itinerary_markers

    trip = self.request.trip
    legs = self.json_legs

    markers = []

    if legs
      legs.each do |leg|

        #place = {:name => leg.start_place.name, :lat => leg.start_place.lat, :lon => leg.start_place.lon, :address => leg.start_place.name}
        place = {:name => self.humanized_origin, :lat => leg['from']['lat'], :lon => leg['from']['lon'], :address => leg['from']['name']}
        markers << self.get_leg_start_marker(place, 'start_leg', 'blueMiniIcon')

        place = {:name => leg['to']['name'], :lat => leg['to']['lat'], :lon => leg['to']['lon'], :address => leg['to']['name']}
        markers << self.get_addr_marker(place, 'end_leg', 'blueMiniIcon')

      end
    end

    # Add start and stop after legs to place above other markers
    place = {:name => self.humanized_origin, :lat => self.request.trip.origin.lat, :lon => self.request.trip.origin.lng, :address => self.humanized_origin}

    markers << self.get_start_stop_marker(place)
    place = {:name => self.humanized_destination, :lat => self.request.trip.destination.lat, :lon => self.request.trip.destination.lng, :address => self.humanized_destination}
    markers << self.get_start_stop_marker(place)

    return markers
  end

  def get_leg_start_marker(addr, id, icon)
    address = addr[:formatted_address].nil? ? addr[:address] : addr[:formatted_address]
    {
        "id" => id,
        "lat" => addr[:lat],
        "lng" => addr[:lon],
        "name" => addr[:name],
        "iconClass" => icon,
        "title" =>  addr[:name], #only diff from get_addr_marker
        "description" => "MAP"
    }
  end

  def get_addr_marker(addr, id, icon)
    address = addr[:formatted_address].nil? ? addr[:address] : addr[:formatted_address]
    {
        "id" => id,
        "lat" => addr[:lat],
        "lng" => addr[:lon],
        "name" => addr[:name],
        "iconClass" => icon,
        "title" =>  address,
        "description" => "MAP"
    }
  end

  def get_start_stop_marker(place)
    get_addr_marker(place, 'start', 'startIcon')
  end

  #Returns an array of polylines, one for each leg
  def create_itinerary_polylines(legs)

    polylines = []
    legs.each_with_index do |leg, index|
      polylines << {
          "id" => index,
          "geom" => leg['geometry'] || [],
          "options" => self.get_leg_display_options(leg)
      }
    end

    return polylines
  end

  # Gets leaflet rendering hash for a leg based on the mode of the leg
  def get_leg_display_options(leg)

    if leg['mode'].nil?
      a = {"className" => 'map-tripleg map-tripleg-unknown'}
    else
      a = {"className" => "map-tripleg", "color" => leg['routeColor'] || "#FFFFFF" }
    end
    return a
  end

end