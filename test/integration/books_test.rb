require 'test_helper'

class BooksTest < ActionDispatch::IntegrationTest
  setup { sign_in users(:reader) }

  test "book pages need a login" do
    get logout_path

    get books_path
    assert_redirected_to login_path
    get book_path(books(:sindhi))
    assert_redirected_to login_path
  end

  test "the index lists the newest books first" do
    get books_path
    assert_response :success
    assert_operator response.body.index('Two Nations'), :<, response.body.index('Shah jo Risalo')
  end

  test "the index searches names and authors" do
    get books_path, params: { q: { name_or_author_or_name_eng_or_author_sindhi_cont: 'Shani' } }
    assert_includes response.body, 'Two Nations'
    assert_not_includes response.body, 'Shah jo Risalo'
    assert_select "input[name='q[name_or_author_or_name_eng_or_author_sindhi_cont]'][value='Shani']"
  end

  test "the index filters by language and category" do
    get books_path, params: { q: { language_eq: 'English' } }
    assert_includes response.body, 'Two Nations'
    assert_not_includes response.body, 'Shah jo Risalo'

    get books_path, params: { q: { categories_name_in: ['Poetry'] } }
    assert_includes response.body, 'Shah jo Risalo'
    assert_not_includes response.body, 'Two Nations'
  end

  test "the index sorts" do
    get books_path, params: { q: { s: 'year asc' } }
    assert_operator response.body.index('Shah jo Risalo'), :<, response.body.index('Two Nations')
  end

  test "the index shows ten books a page" do
    10.times { |i| Book.create!(name: "ڪتاب #{i}", name_eng: "Filler #{i}", author: 'Someone', year: 2000) }

    get books_path
    assert_not_includes response.body, 'Shah jo Risalo'

    get books_path, params: { page: 2 }
    assert_includes response.body, 'Shah jo Risalo'
  end

  test "a book's page shows both languages and renders Markdown" do
    get book_path(books(:sindhi))
    assert_response :success
    assert_includes response.body, 'Shah jo Risalo'
    assert_includes response.body, 'شاهه جو رسالو'
    # Both the wide and the narrow layout render the Markdown.
    assert_equal 2, response.body.scan('<strong>poems</strong>').size
    assert_equal 2, response.body.scan('<strong>مجموعو</strong>').size
  end

  test "the JSON index lists every book with its tags" do
    get books_path(format: :json)
    books = response.parsed_body
    assert_equal 2, books.size
    assert_equal ['Poetry'], books.find { |b| b['name_eng'] == 'Shah jo Risalo' }['categories']
  end

  test "a book's tags are served as JSON" do
    get "/books/#{books(:sindhi).id}/categories.json"
    assert_equal ['Poetry'], response.parsed_body.map { |c| c['name'] }
  end

  test "only admins export the CSV" do
    get books_path(format: :csv)
    assert_redirected_to login_path

    get logout_path
    sign_in users(:admin)
    get books_path(format: :csv)
    assert_response :success
    assert_equal 'text/csv', response.media_type
    assert_includes response.body, 'Shah jo Risalo'
  end

  test "creating a book stores the file and queues its cover" do
    assert_enqueued_with(job: CreateCoversJob) do
      post books_path, params: { book: book_params.merge(attachment: pdf_upload) }
    end

    book = Book.last
    assert_redirected_to book_path(book)
    assert_equal 'sample.pdf', book.attachment.filename.to_s
    assert_equal file_fixture('sample.pdf').binread, book.attachment.download
  end

  test "a failed create pre-fills from the PDF and keeps the file for the resubmit" do
    assert_no_difference 'Book.count' do
      post books_path, params: { book: { attachment: pdf_upload } }
    end
    assert_response :success

    # From the fixture PDF's XMP metadata.
    assert_select 'select[name="book[language]"] option[selected][value="English"]'
    assert_select 'input[name="book[name_eng]"][value="Fixture Title"]'
    assert_select 'input[name="book[author]"][value="Fixture Author"]'
    assert_select 'input[name="book[publisher]"][value="Fixture Press"]'
    assert_select 'input[name="book[year]"][value="1999"]'
    assert_includes response.body, 'Keeping sample.pdf'

    assert_difference 'Book.count', 1 do
      post books_path, params: { book: book_params.merge(attachment: kept_attachment) }
    end
    assert_equal 'sample.pdf', Book.last.attachment.filename.to_s
    assert_equal file_fixture('sample.pdf').binread, Book.last.attachment.download
  end

  test "tags are saved with a new book" do
    post books_path, params: { book: book_params, tags: ['Poetry', 'Folk tales'] }
    assert_equal ['Folk tales', 'Poetry'], Book.last.categories.pluck(:name).sort
  end

  test "editing a book's tags adds and removes them" do
    book = books(:sindhi)

    assert_difference 'Category.count', 1 do
      patch book_path(book), params: { book: { publisher: 'Another publisher' }, tags: ['History', 'New tag'] }
    end
    assert_redirected_to book_path(book)
    assert_equal ['History', 'New tag'], book.reload.categories.pluck(:name).sort
    assert_equal 'Another publisher', book.publisher
  end

  test "replacing the file queues a new cover, other edits don't" do
    book = books(:english)

    assert_no_enqueued_jobs(only: CreateCoversJob) do
      patch book_path(book), params: { book: { publisher: 'Someone' } }
    end
    assert_enqueued_with(job: CreateCoversJob) do
      patch book_path(book), params: { book: { attachment: pdf_upload } }
    end
  end

  test "a book's description cannot smuggle in a script" do
    books(:english).update!(description_eng: "Careful <script>alert(1)</script>", description_sindhi: '')

    get book_path(books(:english))
    assert_response :success
    assert_not_includes response.body, '<script>alert'
    assert_includes response.body, 'Careful'
  end

  test "tags keep the capitals the user typed inside them" do
    post books_path, params: { book: book_params, tags: ['Folk Tales'] }

    assert_equal ['Folk tales'], Book.last.categories.pluck(:name)
  end

  test "a failed create does not create the tags" do
    assert_no_difference ['Book.count', 'Category.count'] do
      post books_path, params: { book: { name_eng: 'No Sindhi name' }, tags: ['Brand new tag'] }
    end
    assert_response :success
  end

  test "only admins delete books" do
    assert_no_difference 'Book.count' do
      delete book_path(books(:english))
    end
    assert_redirected_to login_path

    get logout_path
    sign_in users(:admin)
    assert_difference 'Book.count', -1 do
      delete book_path(books(:english))
    end
    assert_redirected_to books_url
  end

  private

  def book_params
    { name: 'فڪسچر', name_eng: 'Fixture Title', author: 'Fixture Author', year: 1999 }
  end

  # The signed id of the file a failed save kept, as the form sends it back.
  def kept_attachment
    css_select('input[type=hidden][name="book[attachment]"]').first['value']
  end

  def pdf_upload
    fixture_file_upload('sample.pdf', 'application/pdf')
  end
end
