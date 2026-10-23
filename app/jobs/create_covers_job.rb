require 'open3'

# Renders page 1 of a book's PDF as its cover, with poppler's pdftoppm, when
# the browser has not sent one (books/_form.html.erb), and counts the pages
# while the file is downloaded anyway. Never downloads a PDF only to count its
# pages: each download costs S3 traffic (`bin/rails books:count_pages` does the
# rest, by hand). Word files get neither.
class CreateCoversJob < ApplicationJob
  queue_as :default

  # Long side of the cover in pixels.
  SIZE = 1024

  def perform(*books)
    books.each { |book| attach_cover(book) }
  end

  private

  def attach_cover(book)
    return unless book.attachment.attached? && book.attachment.content_type == 'application/pdf'
    return if book.cover.attached?

    # A directory of its own, so covers rendered at the same time cannot
    # overwrite each other.
    Dir.mktmpdir do |dir|
      output = File.join(dir, 'cover')
      book.attachment.open do |pdf|
        book.update_column(:pages, Book.count_pages(pdf.path)) unless book.pages

        _out, err, status = Open3.capture3('pdftoppm', '-singlefile', '-f', '1', '-l', '1', '-scale-to', SIZE.to_s,
                                           '-jpeg', '-jpegopt', 'quality=80', pdf.path, output)
        raise "pdftoppm failed for book #{book.id}: #{err}" unless status.success?

        book.cover.attach(io: File.open("#{output}.jpg"), filename: 'cover.jpg', content_type: 'image/jpeg')
      end
    end
  end
end
