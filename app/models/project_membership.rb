class ProjectMembership < ApplicationRecord
  ROLES = %w[contributor subcontractor observer].freeze

  belongs_to :project
  belongs_to :user

  enum :role, {
    contributor: "contributor",
    subcontractor: "subcontractor",
    observer: "observer"
  }, default: "contributor"

  scope :with_roles, ->(roles) { where(role: roles) }
  scope :messaging_allowed, -> { where(role: %w[contributor subcontractor]) }
  scope :assignable, -> { where.not(role: "observer") }

  validates :user_id, uniqueness: { scope: :project_id }
  validates :role, inclusion: { in: ROLES }

  def messaging_allowed?
    contributor? || subcontractor?
  end

  def attachment_access_allowed?
    !observer?
  end

  def update_allowed?
    contributor?
  end
end
