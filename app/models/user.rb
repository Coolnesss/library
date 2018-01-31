class User < ActiveRecord::Base
  has_secure_password

  validates :email, email: true
  validates :email, uniqueness: true
  validates :name, presence: true
  
end
