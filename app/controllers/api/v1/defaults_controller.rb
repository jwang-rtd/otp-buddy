module Api
  module V1
    class DefaultsController < Api::V1::ApiController

      def index
        render json: Setting.send(self.code)
      end

      def create
        oc = Setting.where(code: self.code).first_or_initialize
        oc.value = params["data"].to_json
        oc.save
        render json: {status: 200, message: "Success"}
      end

      def code
        (params[:type] == "internal") ? "otp_internal_defaults_json" : "otp_external_defaults_json"
      end

      def pass 
        query_string = request.query_string
        query_string.slice!(0,5)
        resp = OTPService.new.pass(query_string)
        render json: {status: 200, message: resp}
      end

    end
  end
end