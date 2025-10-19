class AddDurationToActivities < ActiveRecord::Migration[8.0]
  def change
    add_column :activities, :duration_days, :integer
  end
end
