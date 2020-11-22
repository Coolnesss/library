require 'csv'

class Book < ApplicationRecord

  has_many :book_categories
  has_many :categories, through: :book_categories

  has_attached_file :attachment, default_url: "/files/"
  validates_attachment :attachment, 
    :content_type => { :content_type => %w(application/pdf application/msword application/vnd.openxmlformats-officedocument.wordprocessingml.document), message: "Should be a document" }
  
  has_attached_file :cover, :styles => {
      :original => ["100%", :jpg]
    }, default_url: "/missing.png",
    :convert_options => {
      :all => '-flatten -interlace none -density 200 -quality 80'
  }

  validates :name, presence: true
  validates :name_eng, presence: true
  validates :author, presence: true

  validates :year, presence: true,
    inclusion: { in: (0..2020), message: "Should be between 0 and 2020" },
    numericality: { only_integer: true }
  
  validates :isbn, isbn_format: true, allow_blank: true

  accepts_nested_attributes_for :categories, :allow_destroy => true

  self.per_page = 10

  def self.search(term)
    term = term.downcase
    where("lower(author) LIKE ? OR lower(author_sindhi) LIKE ? OR lower(name_eng) LIKE ? OR lower(name) LIKE ? OR lower(publisher) LIKE ? OR lower(translator) LIKE ?", "%#{term}%", "%#{term}%", "%#{term}%", "%#{term}%", "%#{term}%", "%#{term}%")
  end

  def self.lower_order(sort_column, sort_direction)
    if Book.column_for_attribute(sort_column).type == :integer
      return Book.order(sort_column + " " + sort_direction)
    end
    Book.order("LOWER(" + sort_column + ") " + sort_direction)
  end

  def year_str
    return 'Unknown' if year == 0
    year
  end

  def self.as_csv
    attributes = %w{name name_eng author author_sindhi isbn language year description_sindhi description_eng publisher}

    CSV.generate(headers: true) do |csv|
      csv << attributes

      all.each do |book|
        csv << attributes.map{ |attr| book.send(attr) }
      end
    end
  end
end
