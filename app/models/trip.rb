class Trip < ActiveRecord::Base

  #Associations
  belongs_to :origin, class_name: 'Place', foreign_key: "origin_id"
  belongs_to :destination, class_name: 'Place', foreign_key: "destination_id"
  has_many :requests

  def plan
    requests_array = []
    self.requests.each do |request|
      requests_array << request.plan
    end
    requests_array
  end

end
