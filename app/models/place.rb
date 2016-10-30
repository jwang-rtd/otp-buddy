class Place < ActiveRecord::Base

  #Build a new trip place from PlacesDetails element
  def from_place_details details

    self.lat = details[:geometry][:location][:lat]
    self.lng = details[:geometry][:location][:lng]
    self.save

  end
end
