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

  def humanized_start_time
    return format_time self.start_time
  end

  def humanized_end_time
    return format_time self.end_time
  end

  def format_time(time)
    time.strftime('%l:%M %p').strip
  end

  def humanized_duration options={}
    return humanized_time_in_seconds self.duration, options
  end

  def humanized_walk_time options={}
    return humanized_time_in_seconds self.walk_time, options
  end

  def humanized_time_in_seconds(time_in_seconds, options = {})

    time_in_seconds = time_in_seconds.to_i
    hours = time_in_seconds/3600
    minutes = (time_in_seconds - (hours * 3600))/60

    time_string = ''

    if time_in_seconds > 60*60*24 and options[:days_only]
      count = hours / 24
      return count.to_s + " " + "Day"
    end

    if hours > 0
      time_string << hours.to_s + " " + "hour "
    end

    if minutes > 0 || (hours > 0 and !options[:suppress_minutes])
      time_string << minutes.to_s + " " + "min"
      time_string << "s" if minutes != 1
    end

    if time_in_seconds < 60
      time_string = TranslationEngine.translate_text(:less_than_one_minute)
    end

    if options[:days_only]
      time_string = (hours/24.round).to_s + " day"
    end

    time_string
  end

end