namespace :books do
  # By hand only: it downloads every PDF without a count once (about 20 GB of
  # S3 traffic for the whole library).
  desc "Count the pages of every PDF that has no count yet (for the home page). " \
       "Downloads each of those PDFs once, one at a time."
  task count_pages: :environment do
    books = Book.where(pages: nil).joins(attachment_attachment: :blob)
                .where(active_storage_blobs: { content_type: 'application/pdf' })
    total = books.count
    puts "#{total} PDFs to count"
    books.find_each.with_index(1) do |book, i|
      book.attachment.open { |pdf| book.update_column(:pages, Book.count_pages(pdf.path)) }
      puts "#{i}/#{total}" if (i % 50).zero?
    rescue StandardError => e
      puts "book #{book.id}: #{e.class}: #{e.message}"
    end
    puts "Done: #{Book.sum(:pages)} pages in #{Book.where.not(pages: nil).count} books"
  end
end
