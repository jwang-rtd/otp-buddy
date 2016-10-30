namespace :settings do

  desc "Updating all Settings"
  task :update => :environment do
    settings = [
        {key: 'open_trip_planner', value: "http://otp-rtd.camsys-apps.com:8080/otp/routers/default"},
        {key: 'show_intermediate_stops', value: "true"},
        {key: 'show_stop_times', value: "true"},
        {key: 'otp_walk_reluctance', value: "20"},
        {key: 'otp_transfer_penalty', value: "1800"},
        {key: 'api_activated', value: true},
        {key: 'gtfs_special_route_types', value: ['3']}
    ]

    settings.each do |setting|
      Setting.where(key: setting[:key]).first_or_initialize do |new_setting|
        puts "Creating new setting " + setting[:key].to_s + ' = ' + setting[:value].to_s
        new_setting.value = setting[:value]
        new_setting.save
      end
    end

  end
end