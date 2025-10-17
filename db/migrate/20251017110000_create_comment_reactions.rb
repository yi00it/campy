class CreateCommentReactions < ActiveRecord::Migration[8.0]
  def change
    create_table :comment_reactions do |t|
      t.references :comment, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :emoji, null: false, limit: 8

      t.timestamps
    end

    add_index :comment_reactions, [:comment_id, :user_id, :emoji], unique: true, name: "index_comment_reactions_on_comment_user_emoji"
  end
end
