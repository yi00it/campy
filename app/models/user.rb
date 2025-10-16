class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :projects, foreign_key: :owner_id, inverse_of: :owner, dependent: :destroy
end
