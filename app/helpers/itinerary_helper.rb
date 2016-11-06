module ItineraryHelper
  # This module helps objects speak like a human and not like a computer

  def humanized_origin
    origin = self.request.trip.origin
    return humanized_place origin
  end

  def humanized_destination
    destination = self.request.trip.destination
    return humanized_place destination
  end

  def humanized_place place
    return place.name if place.name
    return "#{place.address}, #{place.city}, #{place.state}"
  end

end