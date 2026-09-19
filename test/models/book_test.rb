require 'test_helper'

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

  test "reads a Sindhi PDF's title and author into the Sindhi fields" do
    book = Book.new(language: 'Sindhi', attachment: file_fixture('sample.pdf').open)
    book.extract_fields_from_metadata

    assert_equal 'Fixture Title', book.name
    assert_equal 'Fixture Author', book.author_sindhi
    assert_nil book.name_eng
    assert_equal 'Fixture Press', book.publisher
    assert_equal 1999, book.year
  end

  test "skips the metadata when there is no PDF to read" do
    assert_nothing_raised do
      Book.new.extract_fields_from_metadata
      Book.new(attachment: file_fixture('sample.pdf').open).tap { |b| b.attachment_content_type = 'application/msword' }.extract_fields_from_metadata
    end
  end

  test "never overwrites what the user typed" do
    book = Book.new(name_eng: 'Typed', attachment: file_fixture('sample.pdf').open)
    book.extract_fields_from_metadata

    assert_equal 'Typed', book.name_eng
    assert_equal 'Fixture Author', book.author
  end
end
