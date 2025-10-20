class AddPerformanceIndexes < ActiveRecord::Migration[8.0]
  def change
    # Activities are frequently sorted by start_on and due_on in Gantt views
    add_index :activities, :start_on unless index_exists?(:activities, :start_on)
    add_index :activities, :due_on unless index_exists?(:activities, :due_on)
    add_index :activities, [:project_id, :start_on] unless index_exists?(:activities, [:project_id, :start_on])

    # Project memberships are used for access control queries
    add_index :project_memberships, :project_id unless index_exists?(:project_memberships, :project_id)
    add_index :project_memberships, :user_id unless index_exists?(:project_memberships, :user_id)

    # Comments with threading support
    add_index :comments, :parent_id unless index_exists?(:comments, :parent_id)

    # Calendar events are queried by date ranges (using start_at/end_at, not start_time/end_time)
    add_index :calendar_events, :start_at unless index_exists?(:calendar_events, :start_at)
    add_index :calendar_events, :end_at unless index_exists?(:calendar_events, :end_at)

    # Project invitations are queried by email (already indexed, skip status as it doesn't exist)
    # Email is already indexed via unique index on [project_id, email]
  end
end
