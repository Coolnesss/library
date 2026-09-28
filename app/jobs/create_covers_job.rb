require 'open3'

# Renders page 1 of a book's PDF as its cover, with poppler's pdftoppm. Word
# files get no cover.
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

    # A directory of its own, so covers rendered at the same time cannot
    # overwrite each other.
    Dir.mktmpdir do |dir|
      output = File.join(dir, 'cover')
      book.attachment.open do |pdf|
        _out, err, status = Open3.capture3('pdftoppm', '-singlefile', '-f', '1', '-l', '1', '-scale-to', SIZE.to_s,
                                           '-jpeg', '-jpegopt', 'quality=80', pdf.path, output)
        raise "pdftoppm failed for book #{book.id}: #{err}" unless status.success?
      end

      book.cover.attach(io: File.open("#{output}.jpg"), filename: 'cover.jpg', content_type: 'image/jpeg')
    end
  end
end
