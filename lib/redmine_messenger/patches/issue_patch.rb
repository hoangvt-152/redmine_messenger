module RedmineMessenger
  module Patches
    module IssuePatch
      extend ActiveSupport::Concern

      included do
        include InstanceMethods

        after_create_commit :send_messenger_create
        after_update_commit :send_messenger_update
      end

      module InstanceMethods
        def send_messenger_create
          channels = Messenger.channels_for_project project
          url = Messenger.url_for_project project

          if Messenger.setting_for_project(project, :messenger_direct_users_messages)
            notified_users.each do |user|
              channels.append "@#{user.login}" if user.login != author.login
            end
          end

          return unless channels.present? && url
          return if is_private? && !Messenger.setting_for_project(project, :post_private_issues)

          set_language_if_valid Setting.default_language

          attachment = {}
          if description.present? && Messenger.setting_for_project(project, :new_include_description)
            attachment[:text] = Messenger.markup_format description
          end
          attachment[:fields] = [{ title: I18n.t(:field_status),
                                   value: Messenger.markup_format(status.to_s),
                                   short: true },
                                 { title: I18n.t(:field_priority),
                                   value: Messenger.markup_format(priority.to_s),
                                   short: true }]
          if assigned_to.present?
            attachment[:fields] << { title: I18n.t(:field_assigned_to),
                                     value: Messenger.markup_format(assigned_to.to_s),
                                     short: true }
          end

          attachments.each do |att|
            attachment[:fields] << { title: I18n.t(:label_attachment),
                                     value: "<#{Messenger.object_url att}|#{ERB::Util.html_escape att.filename}>",
                                     short: true }
          end

          if RedmineMessenger.setting?(:display_watchers) && watcher_users.count.positive?
            attachment[:fields] << {
              title: I18n.t(:field_watcher),
              value: Messenger.markup_format(watcher_users.join(', ')),
              short: true
            }
          end

          #Messenger.speak l(:label_messenger_issue_created,
          #                  project_url: Messenger.project_url_markdown(project),
          #                  url: send_messenger_mention_url(project, description),
          #                  user: author),
          #                channels, url, attachment: attachment, project: project
          begin
          msg = l(:label_messenger_issue_created,
                            project_url: Messenger.project_url_markdown(project),
                            url: send_messenger_mention_url(project, description),
                            user: author)
          map_redmin_uid_to_discord_uid =  Messenger.map_redmin_uid_to_discord_uid
          discord_mention_userId = map_redmin_uid_to_discord_uid[self.assigned_to_id.to_s]
          Messenger.send_to_discord(url,build_discord_params(discord_mention_userId,msg))
          rescue => e 
              puts e.inspect
          end                  
        end

        def send_messenger_update
          return if current_journal.nil?
          puts "============send_messenger_update START==============="
          puts "current_journal: #{current_journal.inspect}"
          puts "issue:#{self.inspect}"
          channels = Messenger.channels_for_project project
          url = Messenger.url_for_project project
          puts ""
          if Messenger.setting_for_project(project, :messenger_direct_users_messages)
            notified_users.each do |user|
              channels.append "@#{user.login}" if user.login != current_journal.user.login
            end
          end

          return unless channels.present? && url && Messenger.setting_for_project(project, :post_updates)
          return if is_private? && !Messenger.setting_for_project(project, :post_private_issues)
          return if current_journal.private_notes? && !Messenger.setting_for_project(project, :post_private_notes)

          set_language_if_valid Setting.default_language

          attachment = {}
          if Messenger.setting_for_project(project, :updated_include_description)
            attachment_text = Messenger.attachment_text_from_journal current_journal
            attachment[:text] = attachment_text if attachment_text.present?
          end

          fields = current_journal.details.map { |d| Messenger.detail_to_field(d, project) }
          fields << { title: I18n.t(:field_is_private), short: true } if current_journal.private_notes?
          fields.compact!
          attachment[:fields] = fields if fields.any?
          project_url = Messenger.project_url_markdown(project)
          puts ""
          msg = l(:label_messenger_issue_updated,
                            project_url: Messenger.project_url_markdown(project),
                            url: send_messenger_mention_url(project, description),
                            user: current_journal.user)
          begin
            map_redmin_uid_to_discord_uid =  Messenger.map_redmin_uid_to_discord_uid
            discord_mention_userId = map_redmin_uid_to_discord_uid[self.assigned_to_id.to_s]
            Messenger.send_to_discord(url,build_discord_params(discord_mention_userId,msg))
          rescue =>e
            puts "Test"
            puts e.inspect
          end
         puts "#{url}" 
         puts "============send_messenger_update END==============="

        end

        private
        def build_discord_params(assigned_to_id,msg)
            discord_params = {'content' =>"<@#{assigned_to_id}>```#{msg}```"}
            discord_params["username"]= RedmineMessenger.settings[:messenger_username]
            discord_params["avatar_url"]= RedmineMessenger.settings[:messenger_icon]
            return discord_params
        end

        def send_messenger_mention_url(project, text)
          mention_to = ''
          if Messenger.setting_for_project(project, :auto_mentions) ||
             Messenger.textfield_for_project(project, :default_mentions).present?
            mention_to = Messenger.mentions project, text
          end
          "#{Messenger.markup_format self}#{mention_to}|#{Messenger.object_url self} "
        end
      end
    end
  end
end
