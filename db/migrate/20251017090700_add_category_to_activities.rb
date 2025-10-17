class AddCategoryToActivities < ActiveRecord::Migration[8.0]
  def change
    add_reference :activities, :category, foreign_key: true
  end
end
