require 'csv'
require 'open3'

class Book < ApplicationRecord

  has_many :book_categories
  has_many :categories, through: :book_categories

  has_one_attached :attachment
  # The thumbnail is made when a cover is attached; covers attached before
  # then get theirs on first view.
  has_one_attached :cover do |cover|
    cover.variant :thumb, resize_to_limit: [160, 240], preprocessed: true
  end

  DOCUMENT_TYPES = %w[
    application/pdf
    application/msword
    application/vnd.openxmlformats-officedocument.wordprocessingml.document
  ].freeze
  validate :attachment_is_a_document
  validate :cover_is_an_image

  validates :name, presence: true
  validates :name_eng, presence: true
  validates :author, presence: true

  validates :year, presence: true,
    numericality: { only_integer: true }
  
  validates :isbn, isbn_format: { message: :invalid_isbn }, allow_blank: true

  before_save :apply_tag_names, if: -> { @tag_names }

  self.per_page = 10

  # The numbers for the home page (all books) and the book list (the books
  # found: `Book.where(id: ...).stats`), leaving out what is not known. Pages are counted
  # by the cover job and `bin/rails books:count_pages`; the total shows once
  # nearly every PDF has a count, so a half-done count does not undersell it.
  def self.stats
    pdfs = joins(attachment_attachment: :blob).where(active_storage_blobs: { content_type: 'application/pdf' })
    counted = pdfs.where.not(pages: nil).count
    {
      books: count,
      pages: (sum(:pages) if counted.positive? && counted >= pdfs.count * 0.95),
      languages: where.not(language: [nil, '', 'Other']).distinct.count(:language),
      authors: where.not(author: [nil, '']).count(Arel.sql('DISTINCT lower(trim(author))')),
      oldest: where('year > 0').minimum(:year),
      size: ActiveStorage::Blob.joins(:attachments)
                               .where(active_storage_attachments: { record_type: 'Book', name: 'attachment', record_id: select(:id) })
                               .sum(:byte_size).nonzero?,
    }.compact
  end

  # The page count from poppler's pdfinfo, or nil if it cannot tell.
  def self.count_pages(path)
    out, status = Open3.capture2('pdfinfo', path.to_s)
    out[/^Pages:\s+(\d+)/, 1]&.to_i if status.success?
  end

  # 0 means the year is unknown.
  def year_str
    return I18n.t('books.unknown_year') if year == 0
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

  # The book form sends its tag chips as book[tag_names][], plus one blank
  # entry so that removing every chip still sends the list. The tags change
  # only when the book saves, so a failed save leaves them and creates none.
  def tag_names
    @tag_names || categories.map(&:name)
  end

  def tag_names=(names)
    @tag_names = Array(names).map { |name| name.to_s.strip.capitalize }.reject(&:blank?).uniq
  end

  private

  # Existing categories are matched case-insensitively, so "Folk Tales" does
  # not become a second "Folk tales".
  def apply_tag_names
    self.categories = @tag_names.map do |name|
      Category.where('lower(name) = ?', name.downcase).first || Category.create!(name: name)
    end
    @tag_names = nil
  end

  def attachment_is_a_document
    return unless attachment.attached?

    errors.add(:attachment, :not_a_document) unless DOCUMENT_TYPES.include?(attachment.content_type)
  end

  # The cover comes from the browser (books/_form.html.erb) as a signed id.
  def cover_is_an_image
    return unless cover.attached?

    errors.add(:cover, :not_an_image) unless cover.content_type.to_s.start_with?('image/')
  end
end
