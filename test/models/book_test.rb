require 'test_helper'
require 'minitest/mock'

class BookTest < ActiveSupport::TestCase
  test "requires names in both languages, an author and a numeric year" do
    book = Book.new
    assert_not book.valid?
    assert_equal %i[author name name_eng year], book.errors.attribute_names.sort

    book = books(:english)
    book.year = 'soon'
    assert_not book.valid?
  end

  test "checks the ISBN only when one is given" do
    book = books(:english)
    assert book.valid?

    book.isbn = '123'
    assert_not book.valid?

    book.isbn = '9780520960916'
    assert book.valid?
  end

  test "a year of 0 is shown as Unknown" do
    assert_equal 'Unknown', Book.new(year: 0).year_str
    assert_equal 2007, books(:english).year_str
  end

  test "picks the font class from the book's language" do
    assert_equal 'sindhi', books(:sindhi).font_html_class
    assert_equal 'not-sindhi-arabic', Book.new(language: 'Urdu').font_html_class
  end

  test "exports CSV with a header row" do
    csv = CSV.parse(Book.order(:year).as_csv, headers: true)
    assert_equal %w[Shah\ jo\ Risalo Two\ Nations], csv.map { |row| row['name_eng'] }
  end

  test "reads an English PDF's title and author into the English fields" do
    book = Book.new(attachment: uploaded_pdf)
    book.extract_fields_from_metadata

    assert_equal 'Fixture Title', book.name_eng
    assert_equal 'Fixture Author', book.author
    assert_nil book.name
    assert_equal 'Fixture Press', book.publisher
    assert_equal 1999, book.year
  end

  test "puts a Sindhi title and author into the Sindhi fields, even with no Language" do
    book = Book.new(attachment: uploaded_pdf)
    book.stub(:attachment_metadata, { 'title' => 'هڪ سسئي سو سور (ناول)', 'creator' => 'امرتا پريتم' }) do
      book.extract_fields_from_metadata
    end

    assert_equal 'هڪ سسئي سو سور (ناول)', book.name
    assert_equal 'امرتا پريتم', book.author_sindhi
    assert_nil book.name_eng
    assert_nil book.author
  end

  test "file URLs escape Sindhi names and spaces" do
    ActiveStorage::Current.url_options = { host: 'example.com' }
    book = books(:english)
    book.attachment.attach(io: file_fixture('sample.pdf').open, filename: 'عاشق جيوڙو (ڪهاڻي).pdf')

    url = book.attachment.url
    assert_not_includes url, ' '
    assert url.end_with?('/%D8%B9%D8%A7%D8%B4%D9%82%20%D8%AC%D9%8A%D9%88%DA%99%D9%88%20(%DA%AA%D9%87%D8%A7%DA%BB%D9%8A).pdf'), url
  end

  test "only takes documents" do
    book = books(:english)
    book.attachment.attach(io: StringIO.new('not a book'), filename: 'notes.txt', content_type: 'text/plain')

    assert_not book.valid?
    assert_includes book.errors[:attachment], 'Should be a document'
  end

  test "skips the metadata when there is no PDF to read" do
    assert_nothing_raised do
      Book.new.extract_fields_from_metadata
      Book.new(attachment: uploaded_pdf(content_type: 'application/msword')).extract_fields_from_metadata
    end
  end

  test "never overwrites what the user typed" do
    book = Book.new(name_eng: 'Typed', attachment: uploaded_pdf)
    book.extract_fields_from_metadata

    assert_equal 'Typed', book.name_eng
    assert_equal 'Fixture Author', book.author
  end

  private

  # extract_fields_from_metadata reads an uploaded blob, as after a failed create.
  def uploaded_pdf(content_type: 'application/pdf')
    ActiveStorage::Blob.create_and_upload!(io: file_fixture('sample.pdf').open, filename: 'sample.pdf',
                                           content_type: content_type, identify: false)
  end
end
