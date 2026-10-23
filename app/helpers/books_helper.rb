module BooksHelper
  # The storage service is public, so this is a direct link that does not expire.
  def cover_url(book)
    book.cover.attached? ? book.cover.url : '/missing.png'
  end

  # Goes through Rails, which makes the thumbnail if it is not there yet and
  # redirects to it.
  def cover_thumb_url(book)
    book.cover.attached? ? url_for(book.cover.variant(:thumb)) : '/missing.png'
  end

  # Each bilingual field as [Sindhi column, English column].
  BILINGUAL = {
    title: %w[name name_eng],
    author: %w[author_sindhi author],
    translator: %w[translator_sindhi translator],
    description: %w[description_sindhi description_eng],
  }.freeze

  # The page's language first.
  def page_languages
    rtl? ? [:sindhi, :english] : [:english, :sindhi]
  end

  # One language of a field as [text, html attributes], or nil when empty.
  # Sindhi-script text gets the book's font (Urdu and the like use Nastaliq).
  def book_text(book, field, language)
    sindhi, english = BILINGUAL.fetch(field)
    if language == :sindhi
      [book[sindhi], { dir: 'rtl', class: book.font_html_class }] if book[sindhi].present?
    else
      [book[english], { dir: 'ltr', lang: 'en' }] if book[english].present?
    end
  end

  # Both languages of a field, the page's first, leaving out empty ones.
  def book_texts(book, field)
    page_languages.filter_map { |language| book_text(book, field, language) }
  end

  # Languages are stored in English; only the label is translated.
  def language_name(language)
    t(language, scope: :languages, default: language)
  end

  def language_options
    LanguageHelper.languages.map { |language| [language_name(language), language] }
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

  # Title and author sort by the page's language; a sort by the other
  # language's column still shows as active. Without a key: newest first.
  def sort_link(search, label, keys = [])
    active = keys.empty? ? search.sort.nil? : keys.include?(search.sort)
    path = if keys.empty?
      books_search_path(sort: nil, dir: nil)
    else
      key = rtl? ? keys.last : keys.first
      books_search_path(sort: key, dir: active && search.dir == 'asc' ? 'desc' : 'asc')
    end
    arrow = { 'asc' => ' ▲', 'desc' => ' ▼' }[search.dir] if active && keys.any?
    link_to "#{label}#{arrow}", path, class: ('active' if active), 'aria-current': (true if active)
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
    chips << [t('books.search.language'), language_name(search.language), books_search_path(language: nil)] if search.language
    search.tags.each do |tag|
      chips << [t('books.search.tag'), tag, books_search_path(tags: search.tags - [tag])]
    end
    chips
  end
end
