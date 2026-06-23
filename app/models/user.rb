class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :api_keys, dependent: :destroy

  def admin?
    admin == true
  end
end
