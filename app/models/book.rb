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

  accepts_nested_attributes_for :categories, :allow_destroy => true

  self.per_page = 20

  def self.search(search)
    where("author LIKE ? OR name_eng LIKE ? OR name LIKE ?", "%#{search}%", "%#{search}%", "%#{search}%")
  end

  def self.lower_order(sort_column, sort_direction)
    if Book.column_for_attribute(sort_column).type == :integer
      return Book.order(sort_column + " " + sort_direction)
    end
    Book.order("LOWER(" + sort_column + ") " + sort_direction)
  end
end
