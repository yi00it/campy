class CreateConversations < ActiveRecord::Migration[8.0]
  def change
    create_table :conversations do |t|
      t.timestamps
    end

    create_table :conversation_memberships do |t|
      t.references :conversation, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :conversation_memberships, [:conversation_id, :user_id], unique: true, name: "index_conversation_memberships_on_conversation_and_user"
    add_index :conversation_memberships, [:user_id, :conversation_id]

    create_table :messages do |t|
      t.references :conversation, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :body, null: false

      t.timestamps
    end
  end
end
