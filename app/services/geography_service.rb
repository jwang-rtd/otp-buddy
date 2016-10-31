class GeographyService

  def global_boundary_as_geojson
    mercator_factory = RGeo::Geographic.simple_mercator_factory
    if Setting.global_boundary.nil?
      return nil
    else
      boundary_shape = mercator_factory.parse_wkt(Setting.global_boundary)
      return RGeo::GeoJSON.encode boundary_shape
    end
  end

end