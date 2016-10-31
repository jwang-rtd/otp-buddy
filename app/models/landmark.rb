class Landmark < ActiveRecord::Base
  scope :is_old, -> { where(:old => true) }
  scope :is_new, -> { where(:old => false) }
  scope :pois, -> { where(:landmark_type => 'POI') }
  scope :stops, -> { where(:landmark_type => 'STOP') }
end
