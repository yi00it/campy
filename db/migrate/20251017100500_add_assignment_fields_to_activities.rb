class AddAssignmentFieldsToActivities < ActiveRecord::Migration[8.0]
  def change
    add_reference :activities, :assignee, foreign_key: { to_table: :users }
    add_column :activities, :start_on, :date

    reversible do |dir|
      dir.up do
        execute <<~SQL
          UPDATE activities
          SET start_on = COALESCE(due_on, DATE(created_at))
        SQL
      end
    end
  end
end
