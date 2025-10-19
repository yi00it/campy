class UpdateWbsStructure < ActiveRecord::Migration[8.0]
  def change
    rename_table :categories, :disciplines

    rename_column :activities, :category_id, :discipline_id
    if index_name_exists?(:disciplines, "index_categories_on_name")
      rename_index :disciplines, "index_categories_on_name", "index_disciplines_on_name"
    end
    if index_name_exists?(:activities, "index_activities_on_category_id")
      rename_index :activities, "index_activities_on_category_id", "index_activities_on_discipline_id"
    end

    create_table :zones do |t|
      t.string :name, null: false
      t.timestamps
    end

    add_index :zones, :name, unique: true
    add_reference :activities, :zone, foreign_key: true
  end
end
