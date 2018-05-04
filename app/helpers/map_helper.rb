module MapHelper

  require 'open-uri'

  def create_static_map

    legs = self.json_legs
    markers = self.create_itinerary_markers
    polylines = self.create_itinerary_polylines(legs)

    params = {
        'size' => '700x435',
        'maptype' => 'roadmap'
    }

    iconUrls = {
        'blueMiniIcon' => 'https://maps.gstatic.com/intl/en_us/mapfiles/markers2/measle_blue.png',
        'startIcon' => 'http://maps.google.com/mapfiles/dd-start.png',
        'stopIcon' => 'http://maps.google.com/mapfiles/dd-end.png'
    }

    markersByIcon = markers.group_by { |m| m["iconClass"] }

    url = "https://maps.googleapis.com/maps/api/staticmap?" + params.to_query 
    markersByIcon.keys.each do |iconClass|
      marker = '&markers=icon:' + iconUrls[iconClass]
      markersByIcon[iconClass].each do |icon|
        marker += '|' + icon["lat"].to_s + "," + icon["lng"].to_s
      end
      url += URI::encode(marker)
    end

    polylines.each do |polyline|

      color = polyline["options"]["color"] || '#00FF00'
      color.slice!(0)

      enc = polyline['geom'] #Polylines::Encoder.encode_points(polyline['geom'])
      url += URI::encode('&path=color:0x' + color.to_s + '|weight:5|enc:' + enc)
    end
    puts 'here is the URL'
    url += "&key=AIzaSyBlknhSoVbT4xUbip4dn0-3zpzMZnD2dGQ"
    puts url

    open(url, 'rb').read
  end

  # Create an array of map markers suitable for the Leaflet plugin.
  def create_itinerary_markers

    legs = self.json_legs
    markers = []

    if legs
      legs.each do |leg|

        place = {:name => self.humanized_origin, :lat => leg['from']['lat'], :lon => leg['from']['lon'], :address => leg['from']['name']}
        markers << self.get_addr_marker(place, 'start_leg', 'blueMiniIcon')

        place = {:name => leg['to']['name'], :lat => leg['to']['lat'], :lon => leg['to']['lon'], :address => leg['to']['name']}
        markers << self.get_addr_marker(place, 'end_leg', 'blueMiniIcon')

      end
    end

    # Add start and stop after legs to place above other markers
    place = {:name => self.humanized_origin, :lat => self.request.trip.origin.lat, :lon => self.request.trip.origin.lng, :address => self.humanized_origin}
    markers << self.get_addr_marker(place, 'start_location', 'startIcon')
    place = {:name => self.humanized_destination, :lat => self.request.trip.destination.lat, :lon => self.request.trip.destination.lng, :address => self.humanized_destination}
    markers << self.get_addr_marker(place, 'end_location', 'stopIcon')

    return markers
  end

  def get_addr_marker(addr, id, icon)
    {
        "id" => id,
        "lat" => addr[:lat],
        "lng" => addr[:lon],
        "name" => addr[:name],
        "iconClass" => icon,
        "title" =>  addr[:name],
        "description" => "MAP"
    }
  end

  #Returns an array of polylines, one for each leg
  def create_itinerary_polylines(legs)

    polylines = []
    legs.each_with_index do |leg, index|
      polylines << {
          "id" => index,
          "geom" => leg['legGeometry']['points'] || [],
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
      a = {"className" => "map-tripleg", "color" => leg['routeColor'] || "#000000" }
    end
    return a
  end

end