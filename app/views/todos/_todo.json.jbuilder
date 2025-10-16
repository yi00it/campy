json.extract! todo, :id, :project_id, :title, :description, :is_done, :due_on, :created_at, :updated_at
json.url todo_url(todo, format: :json)
