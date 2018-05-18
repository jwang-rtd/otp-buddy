namespace :landmarks do


  desc "Load new Landmarks"
  task :load_new_landmarks => :environment do

    require 'open-uri'

    begin
      lm = Setting.landmarks_file
    rescue
      puts 'No Landmarks File Specified.  Need to specify Setting.landmarks_file'
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
        unless Setting.support_emails.nil?
          UserMailer.landmarks_failed_email(Setting.support_emails.split(','), error_string, row_string).deliver!
        end
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
      unless Setting.support_emails.nil?
        UserMailer.landmarks_succeeded_email(Setting.support_emails.split(','), non_geocoded_pois).deliver!
      end
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

  desc "Update Synonyms for Shortcuts"
  task :load_synonyms => :environment do
    require 'open-uri'

    begin
      sm = Setting.synonyms_file
    rescue
      puts 'No Synonyms File Specified.  Need to specify Setting.synonyms_file'
      next #Exit the rake task if not file is specified
    end

    puts 'Opening ' + sm.to_s
    synonyms_file = open(sm)

    #Check to see if this file is newer than the last time synonyms where updated
    synonyms = Setting.synonyms

    #if synonyms
    #  if .updated_at > synonyms_file.last_modified
    #    puts sm.to_s + ' is an old file.'
    #    puts 'Synonyms were last updated at: ' + synonyms.updated_at.to_s
    #    puts sm.to_s + ' was last update at ' + synonyms_file.last_modified.to_s
    #   next
    #  end
    #else
    #  puts 'Creating a new synonyms configuration'
    #  synonyms = Setting.where(key: 'synonyms').first_or_initialize
    #end

    puts 'Uploading New Synonyms'

    #Pull out the synonyms info for each line
    failed = false
    line = 1
    new_synonyms = {}
    contents = CSV.parse synonyms_file
    contents.each do |row|
      unless line == 1 #Skip the first line
        begin
          new_synonyms[row[0]] = row[1]
        rescue
          #Found an error, back out all changes
          error_string = 'Error found on line: ' + line.to_s
          row_string = row
          puts error_string
          puts row
          puts 'No Changes have been made to synonyms.'
          failed = true
          #Email alert of failure
          unless Setting.support_emails.nil?
            UserMailer.synonyms_failed_email(Setting.support_emails.split(','), error_string, row_string).deliver!
          end
          break
        end
      end
      line += 1
    end

    unless failed
      begin
        #Save the new synonyms
        synonyms.value = new_synonyms
        synonyms.save
      rescue
        unless Setting.support_emails.nil?
          UserMailer.synonyms_failed_email(Setting.support_emails.split(','), "Unable to save new synonyms.", "").deliver!
        end
        break
      end
      puts 'Done: Loaded ' + (line - 2).to_s + ' new Synonyms'
      #Alert that the new synonyms file was successfuly updated
      unless Setting.support_emails.nil?
        UserMailer.synonyms_succeeded_email(Setting.support_emails.split(',')).deliver!
      end
    end
  end

  desc "Load in blacklisted Google Places"
  task :load_blacklisted_places => :environment do

    require 'open-uri'
    OpenURI::Buffer.send :remove_const, 'StringMax'
    OpenURI::Buffer.const_set 'StringMax', 0
    failed = false

    blf = Setting.blacklisted_places_file
    unless blf
      puts 'No Blacklisted Place File Specified.  Need to specify Setting.blacklisted_places_file'
      next #Exit the rake task if not file is specified
    end

    blacklist_file = open(blf)
    #Check to see if this file is newer than the last time Pois were updated
    blacklist = Setting.where(key: "blacklisted_places").first_or_initialize

    #If the file is new, updated_at will blank. If it is not blank check the date.
    if blacklist.updated_at
      if blacklist.updated_at > blacklist_file.last_modified
        puts blf.to_s + ' is an old file.'
        puts 'The blacklist was last updated at: ' + blacklist.updated_at.to_s
        puts blf.to_s + ' was last update at ' + blacklist_file.last_modified.to_s
        next
      end
    end

    line = 2
    google_ids = []
    CSV.foreach(blacklist_file, {:col_sep => ",", :headers => true}) do |row|
      begin
        google_ids << row[0]
      rescue
        #Found an error, back out all changes and restore previous POIs
        error_string = 'Error found on line: ' + line.to_s
        row_string = row
        puts error_string
        puts row
        puts 'No changes have been saved'
        failed = true

        #Email alert of failure
        unless Setting.support_emails.nil?
          UserMailer.blacklist_failed_email(Setting.support_emails.split(','), error_string, row_string).deliver!
        end
        break
      end
      line += 1
    end

    unless failed
      blacklist.value = google_ids
      blacklist.save
      #Alert that the new landmarks file was successfuly updated
      unless Setting.support_emails.nil?
        UserMailer.blacklist_succeeded_email(Setting.support_emails.split(',')).deliver!
      end
    end

  end

  desc "Load new Stops"
  task :load_new_stops => :environment do

    tp = OTPService.new
    l = Landmark.where(landmark_type: 'STOP').first
    if l
      if l.updated_at > tp.last_built
        puts  'OpenTripPlanner graph has not been updated since last loading Stops.'
        puts 'Stops were last updated at: ' + l.updated_at.to_s
        puts Setting.open_trip_planner + ' graph was last update at ' + tp.last_built.to_s
        next
      end
    end

    Landmark.where(landmark_type: 'STOP').update_all(old: true)
    failed = false

    og = GeocodingService.new
    geocoded = 0

    stops = tp.get_stops
    stops.each do |stop|

      stop_code = stop['id'].split(':').last  #TODO: The GTFS doesn't have stop_codes, using id for now.
      name = stop['name']
      lat = stop['lat']
      lon = stop['lon']

      l = Landmark.create!({
                          landmark_type: 'STOP',
                          stop_code: stop_code,
                          lng: lon,
                          lat: lat,
                          name: name,
                          old: false,
                      })

      if geocoded < Setting.geocoding_limit or Setting.limit_geocoding == false
        #Reverse Geocode the Lat Lng to fill in the City
        sleep(0.25)
        reverse_geocoded = og.reverse_geocode(l.lat, l.lng)
        if reverse_geocoded[0] and reverse_geocoded[1].count > 0 #No errors?
          l.city = reverse_geocoded[1].first[:city]
          l.save
        end
        geocoded += 1
        puts "Geocoding " + geocoded.to_s + " of " + stops.count.to_s
      else
        puts 'skipping geocoding'
      end

    end

    #Catch any that didn't geocode due to timeout
    if geocoded < Setting.geocoding_limit or Setting.limit_geocoding == false
      ungeocoded = Landmark.where(city: nil, landmark_type: 'STOP', old: false)
      ungeocoded.each do |p|
        #Reverse Geocode the Lat Lng to fill in the City
        sleep(1)
        reverse_geocoded = og.reverse_geocode(l.lat, l.lng)
        if reverse_geocoded[0] and reverse_geocoded[1].count > 0 #No errors?
          l.city = reverse_geocoded[1].first[:city]
          l.save
        end
        geocoded += 1
        puts "Geocoding " + geocoded.to_s + " of " + stops.count.to_s
      end
    end

    ungeocoded = Landmark.where(city: nil, landmark_type: 'STOP', old: false)

    unless failed
      Landmark.where(landmark_type: 'STOP').is_old.delete_all
      Landmark.where(landmark_type: 'STOP').update_all(old: false)
      puts 'Done: Loaded ' + Landmark.where(landmark_type: 'STOP').count.to_s + ' new Stops'
      UserMailer.stops_succeeded_email(Setting.support_emails.split(','), ungeocoded).deliver!
    end

    ungeocoded.destroy_all

  end

  desc "Replace Intersections With Street Address"
  task :replace_intersections => :environment do
    og = GeocodingService.new
    Landmark.all.each do |p|

      unless p.address
        next
      end

      #Intersections from RTD have @ signs in them
      unless ('@').in? p.address
        next
      end

      street_address = og.get_street_address(og.reverse_geocode(p.lat, p.lng))
      if street_address
        puts 'Replacing ' + p.address.to_s + ' with ' + street_address.to_s
        p.address = street_address
        p.save
      end

      #Done to prevent API Errors
      sleep (3)
    end
  end

  desc "Load Landmarks, Stops, and Synonyms"
  task :load_landmarks_stops_and_synonyms => :environment do
    Rake::Task['landmarks:load_new_landmarks'].invoke
    Rake::Task['landmarks:load_synonyms'].invoke
    Rake::Task['landmarks:load_new_stops'].invoke
    Rake::Task['landmarks:load_blacklisted_places'].invoke
    Rake::Task['landmarks:replace_intersections'].invoke
  end

  desc "Destroy All Landmarks"
  task :destroy => :environment do
    Landmark.delete_all
  end

  desc "Clear Blacklisted Places"
  task :destroy_blacklisted_places => :environment do
    s = Setting.find_by(key: 'blacklisted_places')
    if s
      s.delete
    end
  end

  desc "Clear Synonyms"
  task :destroy_synonyms => :environment do
    s = Setting.find_by(key: 'synonyms')
    if s
      s.delete
    end
  end

end