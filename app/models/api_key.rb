class ApiKey < ApplicationRecord
  belongs_to :user

  validates :name, presence: true
  validates :key_digest, presence: true, uniqueness: true
  validates :key_prefix, presence: true, length: { maximum: 8 }

  scope :active, -> { where("expires_at IS NULL OR expires_at > ?", Time.current) }
  scope :expired, -> { where("expires_at IS NOT NULL AND expires_at <= ?", Time.current) }

  def self.generate_key
    raw_key = SecureRandom.hex(32)
    digest = OpenSSL::Digest.new("sha256")
    key_digest = OpenSSL::HMAC.hexdigest(digest, "uptimerobot", raw_key)
    key_prefix = raw_key.first(8)
    [ raw_key, key_digest, key_prefix ]
  end

  def expired?
    expires_at.present? && expires_at <= Time.current
  end

  def active?
    !expired?
  end

  def touch_last_used!
    update_column(:last_used_at, Time.current)
  end
end
