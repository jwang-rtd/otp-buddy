module Api
  module V1
    class PlacesController < Api::V1::ApiController

      def search
        #Get the Search String
        search_string = params[:search_string]
        include_user_pois = params[:include_user_pois]
        max_results = (params[:max_results] || 10).to_i

        locations = []
        count = 0

        #Check for exact match on stop code
        #Cut out white space and remove wildcards
        stripped_string = search_string.tr('%', '').strip
        stop = Landmark.stops.where(stop_code: stripped_string).first
        if stop
          locations.append(stop.build_place_details_hash)
        end

        # Global POIs
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

    end
  end
end