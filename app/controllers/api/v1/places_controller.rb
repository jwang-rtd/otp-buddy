module Api
  module V1
    class PlacesController < Api::V1::ApiController

      def boundary
        gs =  GeographyService.new
        render status: 200, json: gs.global_boundary_as_geojson
      end

    end
  end
end