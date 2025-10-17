class Comment < ApplicationRecord
  belongs_to :activity
  belongs_to :author, class_name: "User", optional: true
  has_many_attached :files
  has_many :comment_reactions, dependent: :destroy

  validates :body, presence: true
end
