class Comment < ApplicationRecord
  belongs_to :todo
  belongs_to :author, class_name: "User", optional: true
  validates :body, presence: true
end
