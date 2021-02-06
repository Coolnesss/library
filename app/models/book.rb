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

  def extract_fields_from_metadata
    return unless self.attachment
    
    temp_pdf = Origami::PDF.read Paperclip.io_adapters.for(attachment)

    pdf_year = temp_pdf.metadata['DateOfPublication']
    pdf_language = temp_pdf.metadata['Language']
    pdf_publisher = temp_pdf.metadata['PublishedBy']
    pdf_title = temp_pdf.metadata['title']
    pdf_author = temp_pdf.metadata['creator']

    if pdf_language and (LanguageHelper.languages.include? pdf_language.capitalize)
      self.language = self.language.presence || pdf_language
    end

    self.publisher = self.publisher.presence || pdf_publisher

    if self.language == 'Sindhi'
      self.name = self.name.presence || pdf_title
      self.author_sindhi = self.author_sindhi.presence || pdf_author
    else
      self.name_eng = self.name_eng.presence || pdf_title
      self.author = self.author.presence || pdf_author
    end

    self.year = self.year.presence || pdf_year
  end

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

  def font_html_class
    if language and (language == "Sindhi" or language == 'Other' or language == 'English')
      return "sindhi"
    end
    
    return "not-sindhi-arabic"
  end

  def self.as_csv
    attributes = %w{name name_eng author author_sindhi isbn language year description_sindhi description_eng publisher}

    CSV.generate(headers: true) do |csv|
      csv << attributes + ['filename', 'url']

      all.each do |book|
        csv << attributes.map{ |attr| book.send(attr) } + [book.attachment.original_filename, book.attachment.url]
      end
    end
  end
end
