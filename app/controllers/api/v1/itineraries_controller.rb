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
        origin.save
        destination.save

        trip.origin = origin
        trip.destination = destination

        #Build a request for each of these modes
        #trip.desired_modes_raw = modes
        #trip.desired_modes = Mode.where(code: modes)

        final_itineraries = []

        # TODO: Make this go away.  Move these fields up to the top level of the call
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
        render json: trip.plan
        return

        ##### DEREK MADE IT THIS FAR


          #Build the itineraries
          tp.create_itineraries

          my_itins = Itinerary.where(trip_part: tp)
          #my_itins = tp.itineraries
          my_itins.each do |itin|
            Rails.logger.info("ITINERARY NUMBER : " + itin.id.to_s)
          end

          Rails.logger.info('Trip part ' + tp.id.to_s + ' generated ' + tp.itineraries.count.to_s + ' itineraries')
          Rails.logger.info(tp.itineraries.inspect)
          #Append data for API
          my_itins.each do |itinerary|
            i_hash = itinerary.as_json(except: 'legs')
            mode = itinerary.mode
            i_hash[:mode] = {name: TranslationEngine.translate_text(mode.name), code: mode.code}
            i_hash[:segment_index] = itinerary.trip_part.sequence
            i_hash[:start_location] = itinerary.trip_part.trip.origin.build_place_details_hash
            i_hash[:end_location] = itinerary.trip_part.trip.destination.build_place_details_hash
            i_hash[:prebooking_questions] = itinerary.prebooking_questions
            i_hash[:bookable] = itinerary.is_bookable?
            if itinerary.service
              i_hash[:service_name] = itinerary.service.name
            else
              i_hash[:service_name] = ""
            end

            if itinerary.discounts
              i_hash[:discounts] = JSON.parse(itinerary.discounts)
            end


            #Open up the legs returned by OTP and augment the information
            unless itinerary.legs.nil?
              yaml_legs = YAML.load(itinerary.legs)

              yaml_legs.each do |leg|
                #1 Add Service Names to Legs if a service exists in the DB that matches the agencyId
                unless leg['agencyId'].nil?
                  service = Service.where(external_id: leg['agencyId']).first
                  unless service.nil?
                    leg['serviceName'] = service.name
                  else
                    leg['serviceName'] = leg['agencyName'] || leg['agencyId']
                  end
                end

                #2 Check to see if this route_type is classified as a special route_type
                begin
                  specials = Oneclick::Application.config.gtfs_special_route_types
                rescue Exception=>e
                  specials = []
                end
                if leg['routeType'].nil?
                  leg['specialService'] = false
                else
                  leg['specialService'] = leg['routeType'].in? specials
                end

                #3 Check to see if real-time is available for node stops
                unless leg['intermediateStops'].blank?
                  trip_time = tp.get_trip_time leg['tripId']
                  unless trip_time.blank?
                    stop_times = trip_time['stopTimes']
                    leg['intermediateStops'].each do |stop|
                      stop_time = stop_times.detect{|hash| hash['stopId'] == stop['stopId']}
                      stop['realtimeArrival'] = stop_time['realtimeArrival']
                      stop['realtimeDeparture'] = stop_time['realtimeDeparture']
                      stop['arrivalDelay'] = stop_time['arrivalDelay']
                      stop['departureDelay'] = stop_time['departureDelay']
                      stop['realtime'] = stop_time['realtime']

                    end
                  end
                end

                #4 If a location is a ParkNRide Denote it
                if leg['mode'] == 'CAR' and itinerary.returned_mode_code == Mode.park_transit.code
                  leg['to']['parkAndRide'] = true
                end

              end
              itinerary.legs = yaml_legs.to_yaml
              itinerary.save
            end




            if itinerary.legs
              i_hash[:json_legs] = (YAML.load(itinerary.legs)).as_json
            else
              i_hash[:json_legs] = nil
            end

            final_itineraries.append(i_hash)

          end

        Rails.logger.info('Sending ' + final_itineraries.count.to_s + ' in the response.')
        origin_in_callnride, origin_callnride = trip.origin.within_callnride?
        destination_in_callnride, destination_callnride = trip.destination.within_callnride?

        render json: {trip_id: trip.id, origin_in_callnride: origin_in_callnride, origin_callnride: origin_callnride, destination_in_callnride: destination_in_callnride, destination_callnride: destination_callnride, trip_token: trip.token, modes: trip.desired_modes_raw, itineraries: final_itineraries}

      end #Plan

    end #Itineraries Controller
  end #V1
end #API
