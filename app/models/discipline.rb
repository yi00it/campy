class Discipline < ApplicationRecord
  has_many :activities, dependent: :restrict_with_exception

  validates :name, presence: true, uniqueness: true
end
