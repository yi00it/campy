class AddProfileFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :username, :string
    add_column :users, :preferred_theme, :string, null: false, default: "light"

    add_index :users, :username, unique: true
  end
end
