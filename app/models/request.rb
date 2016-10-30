class Request < ActiveRecord::Base

  belongs_to :trip
  has_many :itineraries

  def plan
    otp_service = OTPService.new
    otp_request, otp_response = otp_service.plan([self.trip.origin.lat, self.trip.origin.lng],[self.trip.destination.lat, self.trip.destination.lng], Time.now + 2.hours)
    self.otp_request = otp_request
    self.otp_response_code = otp_response.code
    self.otp_response_message = otp_response.message
    self.save

    if otp_response.code == "200"
      body = otp_response.body
      self.otp_response_body = body
      self.save
      create_itineraries JSON.parse(body).to_hash['plan']
    end

  end

  def create_itineraries plan
    plan['itineraries'].collect do |itinerary_hash|
      itinerary = Itinerary.new
      itinerary.request = self
      itinerary.duration = itinerary_hash['duration'].to_f # in seconds
      itinerary.walk_time =  itinerary_hash['walkTime']
      itinerary.transit_time = itinerary_hash['transitTime']
      itinerary.wait_time = itinerary_hash['waitingTime']
      itinerary.transfers = fixup_transfers_count(itinerary_hash['transfers'])
      itinerary.walk_distance = itinerary_hash['walkDistance']
      itinerary.json_legs = itinerary_hash['legs']
      itinerary.save
    end
  end

  def fixup_transfers_count(transfers)
    transfers == -1 ? nil : transfers
  end

end
