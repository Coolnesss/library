class Book < ActiveRecord::Base

  has_many :book_categories
  has_many :categories, through: :book_categories

  def self.search(search)
    where("author LIKE ?", "%#{search}%")
  end
end
