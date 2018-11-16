module Api
  module V1
    class PlacesController < Api::V1::ApiController

      def search
        #Get the Search String
        search_string = params[:search_string]
        include_user_pois = params[:include_user_pois]                         
        max_results = (params[:max_results] || 5).to_i

        locations = []
        
        ##########
        # Stops
        ##########

        #Check for exact match on stop code
        #Cut out white space and remove wildcards
        stripped_string = search_string.tr('%', '').strip.to_s + '%'
        if stripped_string.length >= 4 #Only check once 3 numbers have been entered
          locations = Landmark.stops.where('stop_code LIKE ?', stripped_string).limit(max_results)
        end

        #Check for Stop Names
        stripped_string = search_string.tr('%', '').strip.to_s
        locations += Landmark.get_stops_by_intersection_str(stripped_string, max_results)

        locations.uniq! 
        locations.map!{ |stop| stop.build_place_details_hash}

        ########### End Stops


        ##########
        # POIs
        ##########

        # Global POIs
        count = 0
        landmarks = Landmark.pois.get_by_query_str(search_string, max_results, false)
        landmarks.each do |landmark|
          locations.append(landmark.build_place_details_hash)
          count += 1
          if count >= max_results
            break
          end

        end

        ########### End POIs

        hash = {places_search_results: {locations: locations.uniq}, record_count: locations.count}
        respond_with hash

      end

      def boundary
        gs =  GeographyService.new
        render status: 200, json: gs.global_boundary_as_geojson
      end

      def synonyms
        synonyms = Setting.synonyms
        synonyms.delete_if do |key, value| 
          value.split.include? key
        end
        render status: 200, json: synonyms.as_json
      end

      def blacklist
        blacklist = Setting.blacklisted_places
        render status: 200, json: blacklist.as_json
      end

      def within_area

        origin = params[:geometry]
        lat = origin[:location][:lat]
        lng = origin[:location][:lng]

        gs = GeographyService.new
        if gs.global_boundary_exists?
          render json: {result: gs.within_global_boundary?(lat,lng)}
          return
        end

        render json: {result: false}
      end

    end
  end
end