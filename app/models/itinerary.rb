class Itinerary < ActiveRecord::Base

  include MapHelper
  include ItineraryHelper

  serialize :json_legs
  serialize :fare

  belongs_to :request

  # Move this to a serializer
  def serialized
    start_location = self.request.trip.origin.build_place_details_hash
    end_location = self.request.trip.destination.build_place_details_hash
    json_i = self.as_json 
    json_i["start_location"] = start_location
    json_i["end_location"] = end_location
    json_i["request"] = self.request.otp_request
    return json_i
  end

end
