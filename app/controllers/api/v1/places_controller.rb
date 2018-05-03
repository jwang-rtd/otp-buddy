module Api
  module V1
    class PlacesController < Api::V1::ApiController

      def search
        #Get the Search String
        search_string = params[:search_string]
        include_user_pois = params[:include_user_pois]                          a
        max_results = (params[:max_results] || 5).to_i

        locations = []

        #Check for exact match on stop code
        #Cut out white space and remove wildcards
        stripped_string = search_string.tr('%', '').strip.to_s + '%'
        if stripped_string.length >= 4 #Only check once 3 numbers have been entered
          stops = Landmark.stops.where('stop_code LIKE ?', stripped_string).limit(max_results)
          stops.each do |stop|
            locations.append(stop.build_place_details_hash)
          end
        end

        # Global POIs
        count = 0
        landmarks = Landmark.get_by_query_str(search_string, max_results, true)
        landmarks.each do |landmark|
          locations.append(landmark.build_place_details_hash)
          count += 1
          if count >= max_results
            break
          end

        end

        hash = {places_search_results: {locations: locations}, record_count: locations.count}
        respond_with hash

      end

      def boundary
        gs =  GeographyService.new
        render status: 200, json: gs.global_boundary_as_geojson
      end

      def synonyms
        synonyms = Setting.synonyms
        render status: 200, json: synonyms.as_json
      end

      def blacklist
        blacklist = Setting.blacklisted_places
        render status: 200, json: blacklist.as_json
      end

      def within_area
        
        #TODO REMOVE THIS
        render json: {result: true}
        return 

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