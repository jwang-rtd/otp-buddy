class Itinerary < ActiveRecord::Base

  serialize :json_legs

  belongs_to :request

end
