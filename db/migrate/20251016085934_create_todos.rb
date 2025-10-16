class CreateTodos < ActiveRecord::Migration[8.0]
  def change
    create_table :todos do |t|
      t.references :project, null: false, foreign_key: true
      t.string :title
      t.text :description
      t.boolean :is_done, null: false, default: false
      t.date :due_on

      t.timestamps
    end
  end
end
