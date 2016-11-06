class SettingsController < ApplicationController

  def index
    @boundary = Setting.where(key: 'callnride_boundary').first_or_initialize
    @landmarks_file = Setting.where(key: 'landmarks_file').first_or_initialize
    @synonyms_file = Setting.where(key: 'synonyms_file').first_or_initialize
    @open_trip_planner = Setting.where(key: 'open_trip_planner').first_or_initialize
  end

  def set_callnride_boundary

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

  def set_landmarks_file

    info_msgs = []
    error_msgs = []

    landmarks_file = params[:setting][:value] if params[:setting]

    if !landmarks_file.blank?
      lm = Setting.where(key: 'landmarks_file').first_or_initialize
      lm.value = landmarks_file
      lm.save
    else
      error_msgs << "Landmarks URL cannot be blank."
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

  def set_synonyms_file

    info_msgs = []
    error_msgs = []

    new_value = params[:setting][:value] if params[:setting]

    if !new_value.blank?
      setting = Setting.where(key: 'synonyms_file').first_or_initialize
      setting.value = new_value
      setting.save
    else
      error_msgs << "Synonyms URL cannot be blank."
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

  def set_open_trip_planner

    info_msgs = []
    error_msgs = []

    otp = params[:setting][:value] if params[:setting]

    if !otp.blank?
      setting = Setting.where(key: 'open_trip_planner').first_or_initialize
      setting.value = otp
      setting.save
    else
      error_msgs << "OpenTripPlanner URL cannot be blank."
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