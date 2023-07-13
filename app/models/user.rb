class User < ApplicationRecord
  has_secure_password

  validates :email, 
          :email => {:message => "Please provide a valid email." },
          :uniqueness => {:message => "You already have an account at AntiLibrary."}

  validates :name, 
      :presence => {message: "Please provide a name"}

  before_validation :strip_whitespace, on: :create

  def strip_whitespace
    self.name = self.name.strip unless self.name.nil?
    self.email = self.email.strip unless self.email.nil?
  end
  
  def errors_parsed
    return [] unless self.errors.any?
    self.errors.full_messages.map{|x| if x.split[0] == "Password" then x else x.split.drop(1).join(" ") end}
  end
  
end
