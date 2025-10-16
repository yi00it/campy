class CreateComments < ActiveRecord::Migration[8.0]
  def change
    create_table :comments do |t|
      t.references :todo, null: false, foreign_key: true
      t.text :body
      t.integer :author_id

      t.timestamps
    end
  end
end
