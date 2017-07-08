class Category < ActiveRecord::Base
  has_many :book_categories, dependent: :destroy
  has_many :books, through: :book_categories

  validates :name, uniqueness: true
end
