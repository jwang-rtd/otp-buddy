class Trip < ActiveRecord::Base

  #Associations
  belongs_to :origin, class_name: 'Place', foreign_key: "origin_id"
  belongs_to :destination, class_name: 'Place', foreign_key: "destination_id"

  def plan
    otp_service = OTPService.new
    otp_service.plan([self.origin.lat, self.origin.lng],[self.destination.lat, self.destination.lng], Time.now + 2.hours)
  end

end
