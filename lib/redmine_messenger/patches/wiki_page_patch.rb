module RedmineMessenger
  module Patches
    module WikiPagePatch
      extend ActiveSupport::Concern

      included do
        include InstanceMethods

        after_create_commit :send_messenger_create
        after_update_commit :send_messenger_update
      end

      module InstanceMethods
        def send_messenger_create
          return unless Messenger.setting_for_project project, :post_wiki

          set_language_if_valid Setting.default_language

          channels = Messenger.channels_for_project project
          url = Messenger.url_for_project project

          return unless channels.present? && url

          Messenger.speak l(:label_messenger_wiki_created,
                            project_url: Messenger.project_url_markdown(project),
                            url: Messenger.url_markdown(self, title),
                            user: User.current),
                          channels, url, project: project
        end

        def send_messenger_update
          return unless Messenger.setting_for_project project, :post_wiki_updates

          set_language_if_valid Setting.default_language

          channels = Messenger.channels_for_project project
          url = Messenger.url_for_project project

          return unless channels.present? && url

          attachment = nil
          if !content.nil? && content.comments.present?
            attachment = {}
            attachment[:text] = Messenger.markup_format content.comments.to_s
          end

          Messenger.speak l(:label_messenger_wiki_updated,
                            project_url: Messenger.project_url_markdown(project),
                            url: Messenger.url_markdown(self, title),
                            user: content.author),
                          channels, url, project: project, attachment: attachment
        end
      end
    end
  end
end
