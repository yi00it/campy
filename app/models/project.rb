class Project < ApplicationRecord
  belongs_to :owner, class_name: "User"
  has_many :activities, dependent: :destroy
  has_many :project_memberships, dependent: :destroy
  has_many :members, through: :project_memberships, source: :user

  validates :name, presence: true

  def team_members
    (members + [owner]).uniq
  end

  def accessible_by?(user)
    owner_id == user.id || members.exists?(user.id)
  end
end
