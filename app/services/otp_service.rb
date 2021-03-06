require 'json'
require 'net/http'

class OTPService

  def plan(from,
      to, trip_datetime, arriveBy=true, mode="TRANSIT,WALK", wheelchair="false", walk_speed=3.0,
      max_walk_distance=2, max_bicycle_distance=5, optimize='QUICK', num_itineraries=3,
      min_transfer_time=nil, max_transfer_time=nil, banned_routes=nil, preferred_routes=nil, trip_shown_range_time=nil)

    #walk_speed is defined in MPH and converted to m/s before going to OTP
    #max_walk_distance is defined in miles and converted to meters before going to OTP

    #Parameters
    time = trip_datetime.strftime("%-I:%M%p")
    date = trip_datetime.strftime("%Y-%m-%d")

    base_url = Setting.open_trip_planner + '/plan?'
    url_options = "&time=" + time
    url_options += "&mode=" + mode + "&date=" + date
    url_options += "&toPlace=" + to[0].to_s + ',' + to[1].to_s + "&fromPlace=" + from[0].to_s + ',' + from[1].to_s
    url_options += "&wheelchair=" + wheelchair.to_s
    url_options += "&arriveBy=" + arriveBy.to_s
    url_options += "&walkSpeed=" + (0.44704*walk_speed).to_s
    url_options += "&showIntermediateStops=" + Setting.show_intermediate_stops.to_s
    url_options += "&showStopTimes=" + Setting.show_stop_times.to_s
    url_options += "&showNextFromDeparture=true"

    if banned_routes
      url_options += "&bannedRoutes=" + banned_routes
    end

    if preferred_routes
      url_options += "&preferredRoutes=" + preferred_routes
      url_options += "&otherThanPreferredRoutesPenalty=7200"#VERY High penalty for not using the preferred route
    end

    unless min_transfer_time.nil?
      url_options += "&minTransferTimeHard=" + min_transfer_time.to_s
    end

    unless max_transfer_time.nil?
      url_options += "&maxTransferTime=" + max_transfer_time.to_s
    end

    #If it's a bicycle trip, OTP uses walk distance as the bicycle distance
    if mode == "TRANSIT,BICYCLE" or mode == "BICYCLE"
      url_options += "&maxWalkDistance=" + (1609.34*(max_bicycle_distance || 5.0)).to_s
    else
      url_options += "&maxWalkDistance=" + (1609.34*max_walk_distance).to_s
    end

    url_options += "&numItineraries=" + num_itineraries.to_s

    unless trip_shown_range_time.nil?
      url_options += "&tripShownRangeTime=" + trip_shown_range_time.to_s
    end

    #Unless the optimiziton = QUICK (which is the default), set additional parameters
    case optimize.downcase
      when 'walking'
        url_options += "&walkReluctance=" + Setting.otp_walk_reluctance.to_s
      when 'transfers'
        url_options += "&transferPenalty=" + Setting.otp_transfer_penalty.to_s
    end

    url = base_url + url_options

    Rails.logger.info url

    begin
      resp = Net::HTTP.get_response(URI.parse(url))
    rescue Exception=>e
      return url, {'id'=>500, 'msg'=>e.to_s}
    end

    return url, resp

  end

  def last_built
    url = Setting.open_trip_planner
    resp = Net::HTTP.get_response(URI.parse(url))
    data = JSON.parse(resp.body)
    time = data['buildTime']/1000
    return Time.at(time)
  end

  def get_stops
    stops_path = '/index/stops'
    url = Setting.open_trip_planner + stops_path
    resp = Net::HTTP.get_response(URI.parse(url))
    return JSON.parse(resp.body)
  end

  def get_routes
    routes_path = '/index/routes'
    url = Setting.open_trip_planner + routes_path
    resp = Net::HTTP.get_response(URI.parse(url))
    return JSON.parse(resp.body)
  end

  def get_first_feed_id
    path = '/index/feeds'
    url = Setting.open_trip_planner + path
    resp = Net::HTTP.get_response(URI.parse(url))
    return JSON.parse(resp.body).first
  end

  def get_all_feed_ids
    path = '/index/feeds'
    url = Setting.open_trip_planner + path
    resp = Net::HTTP.get_response(URI.parse(url))
    return JSON.parse(resp.body)
  end


  def get_stoptimes trip_id, agency_id=1
    path = '/index/trips/' + agency_id.to_s + ':' + trip_id.to_s + '/stoptimes'
    url = Setting.open_trip_planner + path
    resp = Net::HTTP.get_response(URI.parse(url))
    return JSON.parse(resp.body)
  end

  def get_otp_mode trip_type
    hash = {'mode_transit': 'TRANSIT,WALK',
    'mode_bicycle_transit': 'TRANSIT,BICYCLE',
    'mode_park_transit':'CAR_PARK,WALK,TRANSIT',
    'mode_car_transit':'CAR,WALK,TRANSIT',
    'mode_bike_park_transit':'BICYCLE_PARK,WALK,TRANSIT',
    'mode_rail':'TRAM,RAIL,SUBWAY,FUNICULAR,GONDOLA,WALK',
    'mode_bus':'BUS,WALK',
    'mode_walk':'WALK',
    'mode_car':'CAR',
    'mode_bicycle':'BICYCLE'}
    hash[trip_type.to_sym]
  end

  def pass path
    url = "#{Setting.open_trip_planner}/#{path}"
    Rails.logger.info("Calling #{url}")
    resp = Net::HTTP.get_response(URI.parse(url))
    Rails.logger.info(resp.body.ai)
    return JSON.parse(resp.body)
  end

end