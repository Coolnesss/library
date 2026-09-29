module BooksHelper
  # The storage service is public, so this is a direct link that does not expire.
  def cover_url(book)
    book.cover.attached? ? book.cover.url : '/missing.png'
  end

  # The book list with the current search changed: nil or blank removes a
  # parameter. Any change starts again from the first page.
  def books_search_path(changes = {})
    books_path(request.query_parameters.except('page').merge(changes.stringify_keys).compact_blank)
  end

  # Adds a tag to the current search, e.g. from a chip in the list.
  def add_tag_path(search, tag)
    books_search_path(tags: search.tags | [tag])
  end

  def sort_header(search, key, label)
    active = search.sort == key
    arrow = { 'asc' => ' ▲', 'desc' => ' ▼' }[search.dir] if active
    link_to "#{label}#{arrow}", books_search_path(sort: key, dir: active && search.dir == 'asc' ? 'desc' : 'asc')
  end

  # One [label, value, path without it] per filter in use, shown as chips.
  def search_filter_chips(search)
    chips = []
    chips << [t('books.search.everywhere'), search.q, books_search_path(q: nil)] if search.q.present?
    BookSearch::FIELDS.each_key do |field|
      value = search.field(field)
      chips << [t("books.search.#{field}"), value, books_search_path(field => nil)] if value.present?
    end
    if search.year_from || search.year_to
      chips << [t('books.search.year'), [search.year_from, search.year_to].map { |year| year || '…' }.join('–'),
                books_search_path(year_from: nil, year_to: nil)]
    end
    chips << [t('books.search.language'), search.language, books_search_path(language: nil)] if search.language
    search.tags.each do |tag|
      chips << [t('books.search.tag'), tag, books_search_path(tags: search.tags - [tag])]
    end
    chips
  end
end
