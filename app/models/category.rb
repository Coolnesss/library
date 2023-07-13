class Category < ApplicationRecord
  has_many :book_categories, dependent: :destroy
  has_many :books, through: :book_categories

  validates :name, uniqueness: true

  def self.ransackable_associations(auth_object = nil)
    ["book"]
  end
  def self.ransackable_attributes(auth_object = nil)
    ["name"]
  end
end
