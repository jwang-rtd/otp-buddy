class Landmark < ActiveRecord::Base

  serialize :types

  scope :has_address, -> { where.not(:address => nil) }
  scope :is_old, -> { where(:old => true) }
  scope :is_new, -> { where(:old => false) }
  scope :pois, -> { where(:landmark_type => 'POI') }
  scope :stops, -> { where(:landmark_type => 'STOP') }


  def self.get_by_query_str(query_str, limit, has_address=false)
    rel = Landmark.arel_table[:name].lower().matches(query_str)
    if has_address
      landmarks = Landmark.has_address.where(rel).limit(limit)
    else
      landmarks = Landmark.where(rel).limit(limit)
    end
    landmarks
  end

  def build_place_details_hash
    #Based on Google Place Details
    {
        address_components: self.address_components,

        formatted_address: self.address,
        place_id: self.google_place_id,
        geometry: {
          location: {
              lat: self.lat,
              lng: self.lng,
          }
        },

        id: self.id,
        name: self.name,
        scope: "user",
        stop_code: self.stop_code,
        types: self.types
    }
  end

  def address_components
    address_components = []

    #street_number
    if self.street_number
      address_components << {long_name: self.street_number, short_name: self.street_number, types: ['street_number']}
    end

    #Route
    if self.route
      address_components << {long_name: self.route, short_name: self.route, types: ['route']}
    end

    #Street Address
    if self.address
      address_components << {long_name: self.address, short_name: self.address, types: ['street_address']}
    end

    #City
    if self.city
      address_components << {long_name: self.city, short_name: self.city, types: ["locality", "political"]}
    end

    #State
    if self.state
      address_components << {long_name: self.state, short_name: self.state, types: ["postal_code"]}
    end

    #Zip
    if self.zip
      address_components << {long_name: self.zip, short_name: self.zip, types: ["administrative_area_level_1","political"]}
    end

    return address_components

  end

end
