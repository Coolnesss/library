class Book < ActiveRecord::Base

  has_many :book_categories
  has_many :categories, through: :book_categories

  has_attached_file :attachment, default_url: "/files/"
  validates_attachment :attachment, 
    :content_type => { :content_type => %w(application/pdf application/msword application/vnd.openxmlformats-officedocument.wordprocessingml.document), message: "Should be a document" }

  validates :name, presence: true
  validates :name_eng, presence: true
  validates :author, presence: true

  validates :year, presence: true,
    inclusion: { in: (0..2020), message: "Should be between 0 and 2020" },
    numericality: { only_integer: true }


  def self.search(search)
    where("author LIKE ?", "%#{search}%")
  end
end
