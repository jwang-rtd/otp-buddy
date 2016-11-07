class Itinerary < ActiveRecord::Base

  include MapHelper
  include ItineraryHelper

  serialize :json_legs

  belongs_to :request

end
