class Setting < ActiveRecord::Base

  serialize :value

  validates :key, presence: true
  validates :key, uniqueness: true

  # Returns the value of a setting when you say Setting.<key>
  def self.method_missing(key, *args, &blk)

    setting = Setting.find_by(key: key)
    if setting.nil?
      return nil
    else
      return setting.value
    end

  end

end
