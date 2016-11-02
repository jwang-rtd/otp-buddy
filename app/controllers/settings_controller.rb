class SettingsController < ApplicationController

  def index
    @boundary = Setting.where(key: 'callnride_boundary').first_or_initialize
  end

  def set_callnride_boundary

    puts params.ai

    info_msgs = []
    error_msgs = []

    boundary_file = params[:setting][:file] if params[:setting]
    if !boundary_file.nil?
      gs = GeographyService.new
      info_msgs << gs.store_callnride_boundary(boundary_file.tempfile.path)
    else
      error_msgs << "Upload a zip file containing a shape file."
    end


    if error_msgs.size > 0
      flash[:error] = error_msgs.join(' ')
    elsif info_msgs.size > 0
      flash[:success] = info_msgs.join(' ')
    end


    respond_to do |format|
      format.js
      format.html {redirect_to settings_path}
    end
  end

end