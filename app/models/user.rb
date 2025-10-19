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
end
