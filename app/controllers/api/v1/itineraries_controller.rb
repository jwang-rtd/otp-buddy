module Api
  module V1
    class ItinerariesController < Api::V1::ApiController

      def plan

        #Unpack params
        modes = params['modes'] || ['mode_transit']
        trip_parts = params[:itinerary_request]
        trip_token = params[:trip_token]
        optimize = params[:optimize]
        max_walk_miles = params[:max_walk_miles]
        max_bike_miles = params[:max_bicycle_miles] # Miles
        max_walk_seconds = params[:max_walk_seconds] # Seconds
        walk_mph = params[:walk_mph] || 3.0
        min_transfer_time = params[:min_transfer_time]
        max_transfer_time = params[:max_transfer_time]
        banned_routes = params[:banned_routes]
        preferred_routes = params[:preferred_routes]
        source_tag = params[:source_tag]

        #Assign Meta Data
        trip = Trip.new
        trip.token = trip_token
        trip.optimize = optimize || "TIME"
        trip.max_walk_miles = max_walk_miles
        trip.max_walk_seconds = max_walk_seconds
        trip.walk_mph = walk_mph
        trip.max_bike_miles = max_bike_miles
        trip.num_itineraries = (params[:num_itineraries] || 3).to_i
        trip.min_transfer_seconds = min_transfer_time.nil? ? nil : min_transfer_time.to_i
        trip.max_transfer_seconds = max_transfer_time.nil? ? nil : max_transfer_time.to_i
        trip.source_tag = source_tag
        trip.arrive_by =

        #Build the Trip Places
        origin = Place.new
        destination = Place.new
        first_part = (trip_parts.select { |part| part[:segment_index] == 0}).first
        origin.from_place_details first_part[:start_location]
        destination.from_place_details first_part[:end_location]
        trip.origin = origin
        trip.destination = destination

        #Build a request for each of these modes
        #trip.desired_modes_raw = modes
        #trip.desired_modes = Mode.where(code: modes)

        trip_part = trip_parts.first
        trip.arrive_by = !(trip_part[:departure_type].downcase == 'depart')
        trip.scheduled_time = trip_part[:trip_time].to_datetime

        #If not feed ID is sent, assume the first feed id.  It's almost always 1
        first_feed_id = OTPService.new.get_first_feed_id

        #Set Banned Routes
        unless banned_routes.blank?
          banned_routes_string = ""
          banned_routes.each do |banned_route|
            if banned_route['id'].blank?
              banned_routes_string +=  first_feed_id.to_s + '_' + banned_route['short_name'] + ','
            else
              banned_routes_string += banned_route['id'].split(':').first + '_' + banned_route['short_name'] + ','
            end
          end
          trip.banned_routes = banned_routes_string.chop
        end

        #Set Preferred Routes
        unless preferred_routes.blank?
          preferred_routes_string = ""
          preferred_routes.each do |preferred_route|
            if preferred_route['id'].blank?
              preferred_routes_string += first_feed_id.to_s + '_' + preferred_route['short_name'] + ','
            else
              preferred_routes_string += preferred_route['id'].split(':').first + '_' + preferred_route['short_name'] + ','
            end

          end
          trip.preferred_routes = preferred_routes_string.chop
        end

        trip.save

        request = Request.new
        request.trip_type = 'mode_transit'
        request.trip = trip
        request.save

        trip.plan

        #TODO: Build the callnride functionality
        #origin_in_callnride, origin_callnride = trip.origin.within_callnride?
        #destination_in_callnride, destination_callnride = trip.destination.within_callnride?
        origin_in_callnride = false
        destination_in_callnride = false
        origin_callnride = nil
        destination_callnride = nil

        render status: 200, json: {trip_id: trip.id, origin_in_callnride: origin_in_callnride, origin_callnride: origin_callnride, destination_in_callnride: destination_in_callnride, destination_callnride: destination_callnride, trip_token: trip.token, itineraries: trip.itineraries.as_json}

      end #Plan

    end #Itineraries Controller
  end #V1
end #API
