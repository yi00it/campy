class ProjectInvitation < ApplicationRecord
  belongs_to :project
  belongs_to :invited_by, class_name: "User"

  before_validation :normalize_email
  before_validation :generate_token, on: :create

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :token, presence: true, uniqueness: true
  validates :project_id, uniqueness: { scope: :email, message: "already has an invitation for that email" }
  validates :role, inclusion: { in: ProjectMembership::ROLES }

  scope :pending_for, ->(email) { where(email: email.to_s.downcase.strip, accepted_at: nil) }
  scope :pending, -> { where(accepted_at: nil) }

  def accept!
    update!(accepted_at: Time.current)
  end

  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end

  def generate_token
    self.token ||= SecureRandom.urlsafe_base64(24)
    self.role ||= ProjectMembership::ROLES.first
  end
end
