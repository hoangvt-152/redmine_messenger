module RedmineMessenger
  module Patches
    module PasswordPatch
      extend ActiveSupport::Concern

      included do
        include InstanceMethods

        after_create_commit :send_messenger_create
        after_update_commit :send_messenger_update
      end

      module InstanceMethods
        def send_messenger_create
          return unless Messenger.setting_for_project project, :post_password
          return if is_private?

          set_language_if_valid Setting.default_language

          channels = Messenger.channels_for_project project
          url = Messenger.url_for_project project

          return unless channels.present? && url

          Messenger.speak l(:label_messenger_password_created,
                            project_url: Messenger.project_url_markdown(project),
                            url: Messenger.url_markdown(self, name),
                            user: User.current),
                          channels, url, project: project
        end

        def send_messenger_update
          return unless Messenger.setting_for_project project, :post_password_updates
          return if is_private?

          set_language_if_valid Setting.default_language

          channels = Messenger.channels_for_project project
          url = Messenger.url_for_project project

          return unless channels.present? && url

          Messenger.speak l(:label_messenger_password_updated,
                            project_url: Messenger.project_url_markdown(project),
                            url: Messenger.url_markdown(self, name),
                            user: User.current),
                          channels, url, project: project
        end
      end
    end
  end
end
