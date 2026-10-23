class User < ApplicationRecord
  has_secure_password

  # The messages are in config/locales, shown under each field.
  validates :email, email: true, uniqueness: true
  validates :name, presence: true

  before_validation :strip_whitespace, on: :create

  def strip_whitespace
    self.name = self.name.strip unless self.name.nil?
    self.email = self.email.strip unless self.email.nil?
  end

end
