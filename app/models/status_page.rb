class StatusPage < ApplicationRecord
  has_many :status_page_monitors, dependent: :destroy
  has_many :monitors, through: :status_page_monitors
  has_many :announcements, dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  scope :published, -> { where(published: true) }
  scope :draft, -> { where(published: false) }

  before_validation :generate_slug, if: -> { slug.blank? && name.present? }

  private

  def generate_slug
    self.slug = name.parameterize
  end
end
