class BookCategory < ApplicationRecord

  belongs_to :book
  belongs_to :category

  validates_uniqueness_of :book_id, :scope => :category_id

end
