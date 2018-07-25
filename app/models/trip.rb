class Trip < ActiveRecord::Base

  #Associations
  belongs_to :origin, class_name: 'Place', foreign_key: "origin_id"
  belongs_to :destination, class_name: 'Place', foreign_key: "destination_id"
  has_many :requests
  has_many :itineraries, through: :requests

  def plan
    found_walk = false
    requests_array = []
    self.requests.each do |request|
      unless found_walk and request.trip_type == 'mode_walk' #If we already found a walk itinerary, no need to explicitely ask for one
        requests_array << request.plan 
        #Check to see if any of these are walks
        request.itineraries.each do |itin|
          if itin[:duration] == itin[:walk_time] and not itin[:duration] == 0 and not itin[:duration].nil?
            found_walk = true
          else
          end
        end
      end
    end
    requests_array
  end

  def errors_hash
    errors  = {}
    requests.each do |request|
      if request.error_text
        errors[request.trip_type] = request.error_text
      end
    end
    return errors 
  end

  def alerts_hash
    alerts  = {}
    requests.each do |request|
      if request.alerts
        alerts[request.trip_type] = request.alerts
      end
    end
    return alerts
  end

end
