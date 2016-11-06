class Itinerary < ActiveRecord::Base

  include ItineraryHelper

  serialize :json_legs

  belongs_to :request

end
