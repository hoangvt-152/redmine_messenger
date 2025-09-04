class AddDirectMessages < ActiveRecord::Migration[4.2]
  def change
    add_column :messenger_settings, :messenger_direct_users_messages, :integer, default: 0, null: false
  end
end
