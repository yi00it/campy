class CommentReaction < ApplicationRecord
  belongs_to :comment
  belongs_to :user

  validates :emoji, presence: true
  validates :user_id, uniqueness: { scope: [:comment_id, :emoji] }
end
