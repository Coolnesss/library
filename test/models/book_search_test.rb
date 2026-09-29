require 'test_helper'

class BookSearchTest < ActiveSupport::TestCase
  def found(params)
    BookSearch.new(params).results.map(&:name_eng)
  end

  test "no search lists every book, newest first" do
    assert_equal ['Two Nations', 'Shah jo Risalo'], found({})
  end

  test "each word of the main box may match a different field" do
    assert_equal ['Shah jo Risalo'], found(q: 'latif risalo')
    assert_empty found(q: 'latif nations')
  end

  test "the main box searches tags and ISBN, with or without hyphens" do
    books(:english).update!(isbn: '978-969-9543-51-7')
    assert_equal ['Shah jo Risalo'], found(q: 'poetry')
    assert_equal ['Two Nations'], found(q: '978-969-9543-51-7')
    assert_equal ['Two Nations'], found(q: '9789699543517')
  end

  test "the main box leaves out the intros; the intro filter searches them" do
    assert_empty found(q: 'collection')
    assert_equal ['Shah jo Risalo'], found(intro: 'collection')
    assert_equal ['Shah jo Risalo'], found(intro: 'مجموعو')
  end

  test "field filters search both languages of a pair" do
    assert_equal ['Shah jo Risalo'], found(title: 'رسالو')
    assert_equal ['Shah jo Risalo'], found(title: 'risalo')
    assert_equal ['Shah jo Risalo'], found(author: 'ڀٽائي')
    books(:english).update!(translator_sindhi: 'مترجم صاحب')
    assert_equal ['Two Nations'], found(translator: 'صاحب')
  end

  test "Sindhi matches across ye and he forms and vowel marks" do
    # Stored with Sindhi ي and ه; searched with Persian ی, Urdu ہ, and a zer.
    assert_equal ['Shah jo Risalo'], found(q: 'شاہہ')
    assert_equal ['Shah jo Risalo'], found(q: 'ڀٽائی')
    assert_equal ['Shah jo Risalo'], found(q: 'رِسالو')
    # And the other way round.
    books(:english).update!(name: 'ٽو نیشنس')
    assert_equal ['Two Nations'], found(q: 'نيشنس')
  end

  test "ک and ڪ stay different letters" do
    books(:english).update!(name: 'ڪتاب')
    assert_empty found(q: 'کتاب')
  end

  test "all words and filters narrow the result" do
    assert_empty found(q: 'shah', language: 'English')
    assert_equal ['Shah jo Risalo'], found(q: 'shah', language: 'Sindhi')
  end

  test "several tags must all be on the book" do
    BookCategory.create!(book: books(:english), category: categories(:history))
    books(:sindhi).categories << categories(:history)
    assert_equal ['Shah jo Risalo'], found(tags: ['poetry', 'History'])
    assert_equal ['Two Nations', 'Shah jo Risalo'], found(tags: ['History'])
  end

  test "years filter a range and leave out unknown years" do
    Book.create!(name: 'نامعلوم', name_eng: 'Undated', author: 'Someone', year: 0)
    assert_equal ['Two Nations'], found(year_from: '2000')
    assert_equal ['Shah jo Risalo'], found(year_to: '1900')
    assert_equal ['Two Nations', 'Shah jo Risalo'], found(year_from: '1800', year_to: '2010')
    assert_includes found({}), 'Undated'
  end

  test "LIKE wildcards are searched literally" do
    assert_empty found(q: '%')
    assert_empty found(q: '_')
  end

  test "books with no year or no Sindhi author sort last either way" do
    assert_equal ['Shah jo Risalo', 'Two Nations'], found(sort: 'author_sindhi', dir: 'desc')
    Book.create!(name: 'نامعلوم', name_eng: 'Undated', author: 'Someone', year: 0)
    assert_equal 'Undated', found(sort: 'year', dir: 'asc').last
    assert_equal 'Undated', found(sort: 'year', dir: 'desc').last
  end

  test "sorting takes known columns only" do
    assert_equal ['Shah jo Risalo', 'Two Nations'], found(sort: 'year', dir: 'asc')
    assert_equal ['Two Nations', 'Shah jo Risalo'], found(sort: 'year', dir: 'desc')
    assert_equal ['Two Nations', 'Shah jo Risalo'], found(sort: 'id; DROP TABLE books', dir: 'asc')
  end
end
