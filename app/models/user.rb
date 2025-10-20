class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :projects, foreign_key: :owner_id, inverse_of: :owner, dependent: :destroy
  has_many :project_memberships, dependent: :destroy
  has_many :member_projects, through: :project_memberships, source: :project
  has_many :assigned_activities, class_name: "Activity", foreign_key: :assignee_id, inverse_of: :assignee, dependent: :nullify
  has_many :conversation_memberships, dependent: :destroy
  has_many :conversations, through: :conversation_memberships
  has_many :messages, dependent: :destroy
  has_many :calendar_events, dependent: :destroy

  has_one_attached :avatar

  before_validation :normalize_username
  after_commit :accept_pending_invitations, on: :create

  validates :username,
            allow_blank: true,
            uniqueness: { case_sensitive: false },
            length: { maximum: 30 },
            format: { with: /\A[a-z0-9_]+\z/i, message: "allows letters, numbers, and underscores only" }
  validates :preferred_theme, inclusion: { in: %w[light dark] }

  has_many :sent_project_invitations, class_name: "ProjectInvitation", foreign_key: :invited_by_id, dependent: :nullify
  has_many :notifications, foreign_key: :recipient_id, dependent: :destroy

  def display_name
    username.presence || email
  end

  def teammate_ids
    @teammate_ids ||= begin
      project_ids = Project.accessible_to(self).pluck(:id)
      if project_ids.empty?
        []
      else
        owner_ids = Project.where(id: project_ids).pluck(:owner_id)
        member_ids = ProjectMembership.messaging_allowed.where(project_id: project_ids).pluck(:user_id)

        (owner_ids + member_ids - [id]).uniq
      end
    end
  end

  def teammates
    return User.none if teammate_ids.empty?

    User.where(id: teammate_ids)
  end

  # Notification helper methods
  def unread_notifications_count
    notifications.unread.count
  end

  def recent_notifications(limit = 10)
    notifications.recent.limit(limit)
  end

  private

  def normalize_username
    self.username = username.to_s.strip.presence&.downcase
  end

  def accept_pending_invitations
    ProjectInvitation.pending_for(email).find_each do |invitation|
      project = invitation.project
      membership = project.project_memberships.find_or_initialize_by(user: self)
      membership.role = invitation.role if membership.new_record?
      membership.save!
      invitation.accept!
    end
  end
end
