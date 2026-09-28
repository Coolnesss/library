require 'csv'

class Book < ApplicationRecord

  has_many :book_categories
  has_many :categories, through: :book_categories

  has_one_attached :attachment
  has_one_attached :cover

  DOCUMENT_TYPES = %w[
    application/pdf
    application/msword
    application/vnd.openxmlformats-officedocument.wordprocessingml.document
  ].freeze
  validate :attachment_is_a_document

  validates :name, presence: true
  validates :name_eng, presence: true
  validates :author, presence: true

  validates :year, presence: true,
    numericality: { only_integer: true }
  
  validates :isbn, isbn_format: true, allow_blank: true

  accepts_nested_attributes_for :categories, :allow_destroy => true

  self.per_page = 10

  def self.ransackable_associations(auth_object = nil)
    ["book_categories", "categories"]
  end

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "author", "language", "name", "name_eng", "year", "isbn", "description_eng", "description_sindhi", "author_sindhi", "publisher"]
  end

  # Reads the PDF's metadata into the fields left empty. The attachment has to
  # be uploaded already (BooksController#create does that for a failed save).
  def extract_fields_from_metadata
    # Submitted without a file, or with a Word file: there is nothing to read.
    # Asking Origami anyway raised, which turned a failed save into a 500.
    return unless attachment.attached? && attachment.blob.persisted? && attachment.content_type == 'application/pdf'

    metadata = attachment_metadata
    return unless metadata

    pdf_year = metadata['DateOfPublication']
    pdf_language = metadata['Language']
    pdf_publisher = metadata['PublishedBy']
    pdf_title = metadata['title']
    pdf_author = metadata['creator']

    if pdf_language and (LanguageHelper.languages.include? pdf_language.capitalize)
      self.language = self.language.presence || pdf_language
    end

    self.publisher = self.publisher.presence || pdf_publisher

    # By the text's script, not the language: most PDFs carry no Language, and
    # a Sindhi title used to land in the English fields.
    if arabic_script?(pdf_title)
      self.name = self.name.presence || pdf_title
    else
      self.name_eng = self.name_eng.presence || pdf_title
    end
    if arabic_script?(pdf_author)
      self.author_sindhi = self.author_sindhi.presence || pdf_author
    else
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

      all.with_attached_attachment.each do |book|
        file = book.attachment
        csv << attributes.map{ |attr| book.send(attr) } + (file.attached? ? [file.filename.to_s, file.url] : [nil, nil])
      end
    end
  end

  private

  def attachment_metadata
    attachment.blob.open { |file| Origami::PDF.read(file.path, lazy: true).metadata }
  rescue StandardError => e
    Rails.logger.warn "Could not read the PDF metadata of #{attachment.filename}: #{e.class}"
    nil
  end

  def arabic_script?(text)
    text.to_s.match?(/\p{Arabic}/)
  end

  def attachment_is_a_document
    return unless attachment.attached?

    errors.add(:attachment, "Should be a document") unless DOCUMENT_TYPES.include?(attachment.content_type)
  end
end
