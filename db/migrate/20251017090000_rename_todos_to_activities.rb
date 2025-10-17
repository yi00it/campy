class RenameTodosToActivities < ActiveRecord::Migration[8.0]
  def up
    remove_foreign_key :comments, :todos
    remove_foreign_key :todos, :projects

    rename_table :todos, :activities
    if index_name_exists?(:activities, "index_todos_on_project_id")
      rename_index :activities, "index_todos_on_project_id", "index_activities_on_project_id"
    end

    rename_column :comments, :todo_id, :activity_id
    if index_name_exists?(:comments, "index_comments_on_todo_id")
      rename_index :comments, "index_comments_on_todo_id", "index_comments_on_activity_id"
    end

    add_foreign_key :activities, :projects
    add_foreign_key :comments, :activities
  end

  def down
    remove_foreign_key :comments, :activities
    remove_foreign_key :activities, :projects

    if index_name_exists?(:comments, "index_comments_on_activity_id")
      rename_index :comments, "index_comments_on_activity_id", "index_comments_on_todo_id"
    end
    rename_column :comments, :activity_id, :todo_id

    if index_name_exists?(:activities, "index_activities_on_project_id")
      rename_index :activities, "index_activities_on_project_id", "index_todos_on_project_id"
    end

    rename_table :activities, :todos

    add_foreign_key :todos, :projects
    add_foreign_key :comments, :todos
  end
end
