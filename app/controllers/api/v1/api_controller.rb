module Api
  module V1
    ## Version 1 of this API makes 2 key assumptions
    ## 1) All bookings are done with via Ecolane
    ## 2) All users are registered to book with only 1 service
    class ApiController < ApplicationController

      respond_to :json
      require 'json'

      protect_from_forgery with: :null_session
      before_action :confirm_api_activated

      protected

      def confirm_api_activated
        unless Setting.api_activated
          hash = {message: "Calls to this API are not authorized."}
          render status: 401, json: hash
        end
      end

      def measure(message, &block)
        start = Time.now
        block.call 
        puts "#{message}: #{Time.now - start}"
      end

    end
  end
end