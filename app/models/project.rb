class Project < ApplicationRecord
  belongs_to :owner, class_name: "User"
  has_many :todos, dependent: :destroy
  validates :name, presence: true
end