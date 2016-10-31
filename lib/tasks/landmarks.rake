namespace :landmarks do


  desc "Load new Landmarks"
  task :load_new_landmarks => :environment do

    require 'open-uri'

    begin
      lm = Setting.landmarks_file
    rescue
      puts 'No Landmarks File Specified.  Need to specify Oneclick::Application.config.landmarks_file'
      next #Exit the rake task if not file is specified
    end

    landmarks_file = open(lm)

    #Check to see if this file is newer than the last time Pois were udpated
    landmark = Landmark.where(landmark_type: "POI").first
    if landmark
      if landmark.updated_at > landmarks_file.last_modified
        puts lm.to_s + ' is an old file.'
        puts 'Landmarks were last updated at: ' + landmark.updated_at.to_s
        puts lm.to_s + ' was last update at ' + landmarks_file.last_modified.to_s
        next
      end
    end

    #Pull out the Landmark info for each line and try to find a google place_id if it exists.
    #Google place IDs are used for RTD
    #RTD has given us a set of Landmarks that should override Google
    failed = false
    Landmark.where(landmark_type: 'POI').update_all(old: true)
    line = 2 #Line 1 is the header, start with line 2 in the count
    gs = GeocodingService.new

    CSV.foreach(landmarks_file, {:col_sep => ",", :headers => true}) do |row|
      begin
        puts row.ai
        poi_name = row[1]
        poi_city = row[3]
        #If we have already created this Landmark, don't create it again.
        if poi_name
          l = Landmark.create!({
                              landmark_type: 'POI',
                              lng: row[13],
                              lat: row[14],
                              name: poi_name,
                              address: row[2],
                              city: poi_city,
                              state: "CO",
                              zip: row[4],
                              old: false,
                          })

          begin
            google_maps_geocode(l, gs) unless google_place_geocode(l)
          rescue Exception => e
            puts e
            puts 'Error Geocoding ' + poi_name.to_s + ' on row ' + line.to_s + '. Continuing . . . '
          end

        end
      rescue
        #Found an error, back out all changes and restore previous POIs
        error_string = 'Error found on line: ' + line.to_s
        row_string = row
        puts error_string
        puts row
        puts 'All changes have been rolled-back and previous Landmarks have been restored'
        Landmark.where(landmark_type: "POI").is_new.delete_all
        Landmark.where(landmark_type: "POI").is_old.update_all(old: false)
        failed = true

        #Email alert of failure
        #unless Oneclick::Application.config.support_emails.nil?
        #  UserMailer.landmarks_failed_email(Oneclick::Application.config.support_emails.split(','), error_string, row_string).deliver!
        #end
        break
      end
      line += 1
    end

    unless failed
      puts 'Done: Loaded ' + (line - 2).to_s + ' new Landmarks'
      Landmark.where(landmark_type: 'POI').is_old.delete_all
      Landmark.where(landmark_type: 'POI').update_all(old: false)

      non_geocoded_pois = Landmark.where(landmark_type: 'POI', google_place_id: nil)

      #Alert that the new landmarks file was successfuly updated
      #unless Oneclick::Application.config.support_emails.nil?
      #  UserMailer.landmarks_succeeded_email(Oneclick::Application.config.support_emails.split(','), non_geocoded_pois).deliver!
      #end
    end

  end

  # Uses the Googole Places API
  def google_place_geocode(poi)
    gs = GeocodingService.new

    location_with_address = poi.address.to_s + ' ' + poi.city.to_s + ', ' + poi.state.to_s + ' ' + poi.zip.to_s

    result = gs.google_place_search(poi.name.to_s)
    if result.body['status'] != 'ZERO_RESULTS'
      place_id = result.body['predictions'].first['place_id']
      poi.google_place_id = place_id
      poi.save
      return true
    else
      result = gs.google_place_search(location_with_address)
      if result.body['status'] != 'ZERO_RESULTS'
        place_id = result.body['predictions'].first['place_id']
        poi.google_place_id = place_id
        poi.save
        return true
      else
        return false
      end
    end
  end

  # Uses Google Geocoder
  def google_maps_geocode(poi, og)

    location_with_name = poi.name.to_s + ', ' + poi.city.to_s + ', ' + poi.state.to_s + ' ' + poi.zip.to_s
    location_with_address_and_name = poi.name.to_s + ', ' + poi.address.to_s + ' ' + poi.city.to_s + ', ' + poi.state.to_s + ' ' + poi.zip.to_s

    geocoded = og.geocode(location_with_name)
    if geocoded[0] and geocoded[1].count > 0 #If there are no errors?
      place_id = geocoded[1].first[:place_id]
      poi.google_place_id = place_id
      poi.save
    else
      #Second try throwing in the address
      geocoded = og.geocode(location_with_address_and_name)
      if geocoded[0] and geocoded[1].count > 0 #If there are no errors?
        place_id = geocoded[1].first[:place_id]
        poi.google_place_id = place_id
        poi.save
      else
        #If the other two attempts fail, just use the Lat,Lng
        reverse_geocoded = og.reverse_geocode(poi.lat, poi.lng)
        if reverse_geocoded[0] and reverse_geocoded[1].count > 0 #No errors?
          place_id = reverse_geocoded[1].first[:place_id]
          poi.google_place_id = place_id
          poi.save
        else
          puts "Unable to find a valid geocode entry for #{poi.name}"
        end
      end
    end
  end

  desc "Load Landmarks, Stops, and Synonyms"
  task :load_landmarks_stops_and_synonyms => :environment do
    Rake::Task['oneclick:load_new_landmarks'].invoke
  end

  desc "Destroy All Landmarks"
  task :destroy => :environment do
    Landmark.delete_all
  end

end