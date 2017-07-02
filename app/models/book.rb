class Book < ActiveRecord::Base

  has_many :book_categories
  has_many :categories, through: :book_categories

  has_attached_file :attachment, default_url: "/files/"
  validates_attachment :attachment, :content_type => { :content_type => %w(application/pdf application/msword application/vnd.openxmlformats-officedocument.wordprocessingml.document) }

  def self.search(search)
    where("author LIKE ?", "%#{search}%")
  end
end
