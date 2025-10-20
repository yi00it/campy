class CalendarEvent < ApplicationRecord
  belongs_to :user
  belongs_to :activity, optional: true

  EVENT_TYPES = %w[custom meeting task].freeze

  validates :title, presence: true
  validates :start_at, presence: true
  validates :end_at, presence: true
  validates :event_type, inclusion: { in: EVENT_TYPES }
  validate :end_after_start

  scope :for_range, lambda { |range|
    range_start = range.begin.to_time.beginning_of_day
    range_end = range.end.to_time.end_of_day
    where("(calendar_events.start_at, calendar_events.end_at) OVERLAPS (?, ?)", range_start, range_end)
  }

  def duration_in_days
    ((end_at.to_date - start_at.to_date).to_i.abs) + 1
  end

  private

  def end_after_start
    return if start_at.blank? || end_at.blank?
    errors.add(:end_at, "must be after the start") if end_at < start_at
  end
end
