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
          url = Messenger.url_for_project project
          begin
            map_redmin_uid_to_discord_uid =  Messenger.map_redmin_uid_to_discord_uid
            assigned_discord_user_id = map_redmin_uid_to_discord_uid[self.assigned_to_id.to_s]
            creator_discord_user_id = map_redmin_uid_to_discord_uid[author.id.to_s]
            issue_label = self.to_s.split(':',-1)
            if  assigned_discord_user_id.nil?
              assigned_discord_user_id = assigned_to
            else
              assigned_discord_user_id = "<@#{assigned_discord_user_id}>"
            end
  
            if  creator_discord_user_id.nil?
              creator_discord_user_id = author
            else
              creator_discord_user_id = "<@#{creator_discord_user_id}>"
            end

            msg = l(:label_messenger_issue_created,issue_id:"#{issue_label[0]}",
                  creator: author,
                  subject:send_messenger_mention_url(project, description),
                  author:creator_discord_user_id,
                  assigned_user:assigned_discord_user_id)
                  
            Messenger.send_to_discord(url,build_discord_params(assigned_discord_user_id,msg))
          rescue => e 
              puts e.inspect
          end                  
        end
=begin
[Issue Updated] #{issue id} has been updated by @{creator}
Subject: <tiêu đề> (hyperlink đến url của ticket luôn),
Author: @{author} (tag chính xác),
Assignee : @{người được giao}(tag chính xác),
Comment : (nếu có)
=end
        def send_messenger_update
          return if current_journal.nil?

          begin
          url = Messenger.url_for_project project
          map_redmin_uid_to_discord_uid =  Messenger.map_redmin_uid_to_discord_uid
          assigned_discord_user_id = map_redmin_uid_to_discord_uid[self.assigned_to_id.to_s]
          creator_discord_user_id = map_redmin_uid_to_discord_uid[author.id.to_s]
          issue_label = self.to_s.split(':',-1)    
          if  assigned_discord_user_id.nil?
            assigned_discord_user_id = assigned_to
          else
            assigned_discord_user_id = "<@#{assigned_discord_user_id}>"
          end

          if  creator_discord_user_id.nil?
            creator_discord_user_id = author
          else
            creator_discord_user_id = "<@#{creator_discord_user_id}>"
          end
                  
          msg = l(:label_messenger_issue_updated,issue_id:"#{issue_label[0]}",
                  creator: current_journal.user,
                  subject:send_messenger_mention_url(project, description),
                  author:creator_discord_user_id,
                  assigned_user:assigned_discord_user_id,
                  comment:current_journal.notes)
          Messenger.send_to_discord(url,build_discord_params(assigned_discord_user_id,msg))
        rescue =>e
            puts "Test"
            puts e.inspect
        end
        puts "#{url}" 
        puts "============send_messenger_update END==============="
      end

        private
        def build_discord_params(assigned_to_id,msg)
            discord_params = {'content' =>msg}
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
          puts "===========mention_to:#{mention_to}"
          puts "===========Messenger.markup_format self:#{Messenger.markup_format self}"
          "[#{Messenger.markup_format self}#{mention_to}](#{Messenger.object_url self}) "
        end
      end
    end
  end
end
