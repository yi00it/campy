json.extract! activity, :id, :project_id, :discipline_id, :zone_id, :title, :description, :is_done, :due_on, :created_at, :updated_at
json.url activity_url(activity, format: :json)
