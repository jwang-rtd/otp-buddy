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

end
