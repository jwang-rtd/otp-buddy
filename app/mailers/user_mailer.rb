class UserMailer < ApplicationMailer

  @@from = ENV['SMTP_MAIL_FROM']

  def landmarks_failed_email(emails, message, row)
    emails.each do |email|
      @message = message
      @row = row
      mail(to: email, from: @@from, subject: 'Landmarks Upload Failed')
    end
  end

  def landmarks_succeeded_email(emails, non_geocoded_pois)
    @non_geocoded_pois = non_geocoded_pois
    emails.each do |email|
      mail(to: email, from: @@from, subject: 'Landmarks Upload Succeeded')
    end
  end

  def stops_failed_email(emails)
    emails.each do |email|
      mail(to: email, from: @@from, subject: 'Stops Upload Failed')
    end
  end

  def stops_succeeded_email(emails, ungeocoded)
    @ungeocoded = ungeocoded
    emails.each do |email|
      mail(to: email, from: @@from, subject: 'Stops Upload Succeeded')
    end
  end

  def synonyms_failed_email(emails, message, row)
    emails.each do |email|
      @message = message
      @row = row
      mail(to: email, from: @@from, subject: 'Synonyms Upload Failed')
    end
  end

  def synonyms_succeeded_email(emails)
    emails.each do |email|
      mail(to: email, from: @@from, subject: 'Synonyms Upload Succeeded')
    end
  end

  def blacklist_failed_email(emails, message, row)
    emails.each do |email|
      @message = message
      @row = row
      mail(to: email, from: @@from, subject: 'Blacklisted Google Places Upload Failed')
    end
  end

  def blacklist_succeeded_email(emails)
    emails.each do |email|
      mail(to: email, from: @@from, subject: 'Blacklisted Google Place Upload Succeeded')
    end
  end

  def user_itinerary_email(addresses, itineraries, subject, trip_link)
    @itineraries = itineraries
    @trip_link = trip_link

    #Add Attachments
    attachments.inline['start.png'] = open("#{Setting.host}#{ActionController::Base.helpers.asset_url('start.png')}", 'rb').read
    attachments.inline['stop.png'] = open("#{Setting.host}#{ActionController::Base.helpers.asset_url('stop.png')}", 'rb').read
    attach_mode_icons @itineraries

    itineraries.each do |itin|
      attachments.inline[itin.id.to_s + '.png'] = itin.create_static_map
    end

    mail(to: addresses, subject: subject, from: @@from)
  end

  private

  # Attaches an asset to the email based on its filename (including extension)
  def attach_mode_icons itineraries
    modes = []
    #Which mode icons should we attach logos for?
    itineraries.each do |itin|
      modes << itin.mode_array
    end
    modes.flatten!.uniq!
    
    modes.each do |mode|
      path = ActionController::Base.helpers.asset_path("#{mode.downcase}.png").to_s
      attachments.inline["#{mode.downcase}.png"] = open("#{Setting.host}#{path}", 'rb').read
    end
  end

end
