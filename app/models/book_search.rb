# The book list's search: one box that looks everywhere, plus optional filters
# for single fields. Every filter narrows the result.
#
# Sindhi text is compared loosely: the Persian/Urdu forms of ye and he match
# the Sindhi ones, and vowel marks (zabar, zer, pesh...) are ignored, because
# books were typed on different keyboards and some carry the marks.
class BookSearch
  PARAMS = [:q, :title, :author, :translator, :publisher, :intro, :year_from, :year_to, :language, :sort, :dir, { tags: [] }].freeze

  # Each field filter searches both languages of its pair.
  FIELDS = {
    title: %w[name name_eng],
    author: %w[author author_sindhi],
    translator: %w[translator translator_sindhi],
    publisher: %w[publisher],
    intro: %w[description_eng description_sindhi],
  }.freeze

  # The main box: everything but the intros, plus ISBN and tags (below).
  EVERYWHERE = %w[name name_eng author author_sindhi translator translator_sindhi publisher].freeze

  SORTS = { 'title' => 'name_eng', 'name' => 'name', 'author' => 'author', 'author_sindhi' => 'author_sindhi', 'year' => 'year' }.freeze

  FOLD = { 'ی' => 'ي', 'ى' => 'ي', 'ہ' => 'ه' }.freeze
  MARKS = ((0x064B..0x0652).to_a + [0x0670, 0x0640]).pack('U*').chars.freeze

  attr_reader :q, :year_from, :year_to, :language, :tags, :sort, :dir

  def initialize(params = {})
    params = params.to_h.symbolize_keys
    @q = params[:q].to_s.squish
    @fields = FIELDS.keys.to_h { |field| [field, params[field].to_s.squish] }
    @year_from = Integer(params[:year_from].to_s, exception: false)
    @year_to = Integer(params[:year_to].to_s, exception: false)
    @language = params[:language].presence
    @tags = Array(params[:tags]).map { |tag| tag.to_s.squish }.reject(&:blank?).uniq { |tag| tag.downcase }
    @sort = params[:sort] if SORTS.key?(params[:sort])
    @dir = params[:dir] == 'desc' ? 'desc' : 'asc'
  end

  def field(name) = @fields.fetch(name)

  # Whether anything in the "more filters" panel is set, so it opens.
  def filtering_fields?
    @fields.values.any?(&:present?) || year_from || year_to || language || tags.any?
  end

  def results
    scope = Book.all
    words(q).each { |word| scope = scope.where(everywhere_sql, like: like(word), isbn: isbn_like(word)) }
    @fields.each do |name, value|
      next if value.blank?
      # Like the main box, each word may sit anywhere in the field.
      words(value).each do |word|
        scope = scope.where(FIELDS[name].map { |column| "#{folded(column)} LIKE :like ESCAPE '\\'" }.join(' OR '), like: like(word))
      end
    end
    if year_from || year_to
      scope = scope.where('year > 0') # 0 is "Unknown"
      scope = scope.where('year >= ?', year_from) if year_from
      scope = scope.where('year <= ?', year_to) if year_to
    end
    scope = scope.where(language: language) if language
    tags.each do |tag|
      scope = scope.where(<<~SQL, tag.downcase)
        EXISTS (SELECT 1 FROM book_categories bc JOIN categories c ON c.id = bc.category_id
                WHERE bc.book_id = books.id AND lower(c.name) = ?)
      SQL
    end
    scope.order(order_sql)
  end

  private

  def words(text)
    text.split.map { |word| fold(word) }
  end

  def fold(text)
    text.gsub(Regexp.union(FOLD.keys), FOLD).delete(MARKS.join)
  end

  # The same folding in SQL, applied to a column.
  def folded(column)
    sql = "COALESCE(#{column}, '')"
    FOLD.each { |from, to| sql = "REPLACE(#{sql}, '#{from}', '#{to}')" }
    MARKS.each { |mark| sql = "REPLACE(#{sql}, '#{mark}', '')" }
    sql
  end

  def like(word)
    "%#{ActiveRecord::Base.sanitize_sql_like(word)}%"
  end

  # ISBNs are stored with hyphens, and pasted with or without them.
  def isbn_like(word)
    digits = word.delete('- ')
    digits.empty? ? nil : like(digits)
  end

  def everywhere_sql
    @everywhere_sql ||= (
      EVERYWHERE.map { |column| "#{folded(column)} LIKE :like ESCAPE '\\'" } +
      ["REPLACE(COALESCE(isbn, ''), '-', '') LIKE :isbn ESCAPE '\\'",
       "EXISTS (SELECT 1 FROM book_categories bc JOIN categories c ON c.id = bc.category_id
                WHERE bc.book_id = books.id AND c.name LIKE :like ESCAPE '\\')"]
    ).join(' OR ')
  end

  def order_sql
    return Arel.sql('books.created_at DESC, books.id DESC') unless sort

    column = "books.#{SORTS[sort]}"
    # Books with no value (or year 0, "Unknown") go last either way.
    blank = sort == 'year' ? "(#{column} IS NULL OR #{column} = 0)" : "(#{column} IS NULL OR #{column} = '')"
    Arel.sql("#{blank}, #{column} #{dir.upcase}, books.id DESC")
  end
end
