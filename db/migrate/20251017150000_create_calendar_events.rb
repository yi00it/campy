class CreateCalendarEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :calendar_events do |t|
      t.references :user, null: false, foreign_key: true
      t.references :activity, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.datetime :start_at, null: false
      t.datetime :end_at, null: false
      t.string :event_type, null: false, default: "custom"
      t.string :location
      t.boolean :all_day, null: false, default: false

      t.timestamps
    end

    add_index :calendar_events, [:user_id, :start_at]
  end
end
