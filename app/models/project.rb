class Project < ApplicationRecord
  belongs_to :owner, class_name: "User"
  has_many :activities, dependent: :destroy
  has_many :project_memberships, dependent: :destroy
  has_many :members, through: :project_memberships, source: :user
  has_many :project_invitations, dependent: :destroy

  validates :name, presence: true

  scope :accessible_to, ->(user) {
    left_outer_joins(:project_memberships)
      .where("projects.owner_id = :user_id OR project_memberships.user_id = :user_id", user_id: user.id)
      .distinct
  }

  def team_members(roles: nil)
    scoped_memberships = project_memberships.includes(:user)
    scoped_memberships = scoped_memberships.with_roles(Array(roles)) if roles.present?
    membership_users = scoped_memberships.map(&:user)
    (membership_users + [owner]).uniq
  end

  def assignable_members
    scoped_memberships = project_memberships.assignable.includes(:user)
    membership_users = scoped_memberships.map(&:user)
    (membership_users + [owner]).uniq
  end

  def messaging_members
    scoped_memberships = project_memberships.messaging_allowed.includes(:user)
    membership_users = scoped_memberships.map(&:user)
    (membership_users + [owner]).uniq
  end

  def accessible_by?(user)
    owner_id == user.id || members.exists?(user.id)
  end
end
