class Activity < ApplicationRecord
  belongs_to :project
  belongs_to :discipline, optional: true
  belongs_to :zone, optional: true
  belongs_to :assignee, class_name: "User", optional: true
  has_many :comments, dependent: :destroy
  has_many_attached :files

  validates :title, presence: true
  validates :start_on, presence: true
  validates :duration_days, numericality: { greater_than: 0 }, allow_blank: true
  validate :due_on_not_before_start
  validate :assignee_is_part_of_project
  before_validation :set_due_on_from_duration

  after_initialize :set_default_dates, if: :new_record?

  private

  def set_default_dates
    self.start_on ||= Date.current
    self.due_on ||= Date.current.tomorrow
  end

  def set_due_on_from_duration
    return unless duration_days.present? && start_on.present?
    self.due_on = start_on + duration_days.to_i.days
  end

  def due_on_not_before_start
    return if start_on.blank? || due_on.blank?

    errors.add(:due_on, "cannot be before the start date") if due_on < start_on
  end

  def assignee_is_part_of_project
    return if assignee.blank? || project.blank?

    errors.add(:assignee, "must belong to the project") unless project.team_members.include?(assignee)
  end
end
