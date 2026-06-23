class MaintenanceWindow < ApplicationRecord
  validates :name, presence: true
  validates :starts_at, presence: true
  validates :ends_at, presence: true

  validate :ends_after_starts

  scope :active, -> { where("starts_at <= ? AND ends_at >= ?", Time.current, Time.current) }
  scope :upcoming, -> { where("starts_at > ?", Time.current) }
  scope :past, -> { where("ends_at < ?", Time.current) }

  def active?
    starts_at <= Time.current && ends_at >= Time.current
  end

  def upcoming?
    starts_at > Time.current
  end

  private

  def ends_after_starts
    return unless starts_at.present? && ends_at.present?

    if ends_at <= starts_at
      errors.add(:ends_at, "must be after starts_at")
    end
  end
end
