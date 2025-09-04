class MessengerSetting < ActiveRecord::Base
  belongs_to :project

  validates :messenger_url, url: { allow_blank: true, message: l(:error_messenger_invalid_url) }

  def self.find_or_create(p_id)
    setting = MessengerSetting.find_by project_id: p_id
    unless setting
      setting = MessengerSetting.new
      setting.project_id = p_id
      setting.save!
    end

    setting
  end
end
