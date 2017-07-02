class BookCategory < ActiveRecord::Base

  belongs_to :book
  belongs_to :category

end
