class AddNotificationPreferencesToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :email_notifications, :boolean, default: true, null: false
    add_column :users, :in_app_notifications, :boolean, default: true, null: false
    add_column :users, :sms_notifications, :boolean, default: false, null: false
    add_column :users, :phone_number, :string
    add_column :users, :daily_digest, :boolean, default: false, null: false
    add_column :users, :digest_time, :string, default: "09:00", null: false
  end
end
