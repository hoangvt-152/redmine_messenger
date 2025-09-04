module MessengerProjectsHelper
  def project_settings_tabs
    tabs = super

    if User.current.allowed_to?(:manage_messenger, @project)
      tabs << { name: 'messenger',
                action: :show,
                partial: 'messenger_settings/show',
                label: :label_messenger }
    end

    tabs
  end
end
