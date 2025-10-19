class Comment < ApplicationRecord
  belongs_to :activity
  belongs_to :author, class_name: "User", optional: true
  has_many_attached :files
  has_many :comment_reactions, dependent: :destroy
  belongs_to :parent, class_name: "Comment", optional: true
  has_many :replies, class_name: "Comment", foreign_key: :parent_id, dependent: :destroy

  validates :body, presence: true

  validate :parent_activity_matches

  scope :roots, -> { where(parent_id: nil) }

  private

  def parent_activity_matches
    return if parent.nil?
    errors.add(:parent, "must belong to the same activity") if parent.activity_id != activity_id
  end
end
