class GeographyService
  require 'zip'

  def global_boundary_as_geojson
    mercator_factory = RGeo::Geographic.simple_mercator_factory
    if Setting.global_boundary.nil?
      return nil
    else
      boundary_shape = mercator_factory.parse_wkt(Setting.global_boundary)
      return RGeo::GeoJSON.encode boundary_shape
    end
  end

  def store_callnride_boundary(shapefile_path)
    shapes = []
    unless shapefile_path.nil?
      begin
        Zip::File.open(shapefile_path) do |zip_file|
          zip_shp = zip_file.glob('**/*.shp').first
          unless zip_shp.nil?
            zip_shp_paths = zip_shp.name.split('/')
            file_name = zip_shp_paths[zip_shp_paths.length - 1].sub '.shp', ''
            shp_name = nil
            Dir.mktmpdir do |dir|
              shp_name = "#{dir}/" + file_name + '.shp'
              zip_file.each do |entry|
                entry_names = entry.name.split('/')
                entry_name = entry_names[entry_names.length - 1]
                if entry_name.include?(file_name)
                  entry.extract("#{dir}/" + entry_name)
                end
              end
              RGeo::Shapefile::Reader.open(shp_name, { :assume_inner_follows_outer => true }) do |shapefile|
                shapefile.each do |shape|
                  if not shape.geometry.nil?
                    shapes << {name: shape.attributes['NAME'], geometry: shape.geometry}
                  end
                end
              end
            end
          end
        end

        oc = Setting.where(key: "callnride_boundary").first_or_initialize
        oc.value = shapes
        oc.save

      rescue Exception => msg
        Rails.logger.info 'shapefile parse error'
        Rails.logger.info msg
        return msg
      end
    end

    return "Call-N-Ride Boundary Updated"
  end

  #TODO Simplify this (Potentially Use RGEO Json library like the global_boundary_as_geojson method)
  def callnride_boundary_array
    if Setting.callnride_boundary.nil?
      return []
    end
    # Returns an array of coverage zone polygon geoms
    myArray = []
    Setting.callnride_boundary.each do |boundary|
      polygon_array = []
      boundary[:geometry].each do |polygon|
        ring_array  = []
        polygon.exterior_ring.points.each do |point|
          ring_array << [point.y, point.x]
        end
        polygon_array << ring_array
        polygon.interior_rings.each do |ring|
          ring_array = []
          ring.points.each do |point|
            ring_array << [point.y, point.x]
          end
          polygon_array << ring_array
        end
      end
      myArray << polygon_array
    end
    myArray
  end

end