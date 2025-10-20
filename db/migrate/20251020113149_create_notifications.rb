class CreateNotifications < ActiveRecord::Migration[8.0]
  def change
    create_table :notifications do |t|
      t.integer :recipient_id, null: false
      t.integer :actor_id
      t.references :notifiable, polymorphic: true, null: false
      t.string :action, null: false
      t.datetime :read_at
      t.text :metadata # JSON data for notification details

      t.timestamps
    end

    add_index :notifications, :recipient_id
    add_index :notifications, :actor_id
    add_index :notifications, [:recipient_id, :read_at]
    add_index :notifications, [:recipient_id, :created_at]

    add_foreign_key :notifications, :users, column: :recipient_id
    add_foreign_key :notifications, :users, column: :actor_id
  end
end
