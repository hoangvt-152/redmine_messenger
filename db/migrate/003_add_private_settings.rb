class AddPrivateSettings < ActiveRecord::Migration[4.2]
  def change
    add_column :messenger_settings, :post_private_contacts, :integer, default: 0, null: false
    add_column :messenger_settings, :post_private_db, :integer, default: 0, null: false
  end
end
