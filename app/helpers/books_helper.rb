module BooksHelper
  # The storage service is public, so this is a direct link that does not expire.
  def cover_url(book)
    book.cover.attached? ? book.cover.url : '/missing.png'
  end
end
