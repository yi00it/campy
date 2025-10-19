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

  has_one_attached :avatar

  before_validation :normalize_username

  validates :username,
            allow_blank: true,
            uniqueness: { case_sensitive: false },
            length: { maximum: 30 },
            format: { with: /\A[a-z0-9_]+\z/i, message: "allows letters, numbers, and underscores only" }
  validates :preferred_theme, inclusion: { in: %w[light dark] }

  def display_name
    username.presence || email
  end

  private

  def normalize_username
    self.username = username.to_s.strip.presence&.downcase
  end
end
