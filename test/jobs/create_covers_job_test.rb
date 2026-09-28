require 'test_helper'

class CreateCoversJobTest < ActiveJob::TestCase
  test "renders page 1 of the PDF as a JPEG cover" do
    skip 'needs poppler (pdftoppm)' unless system('which pdftoppm > /dev/null 2>&1')

    book = books(:english)
    book.attachment.attach(io: file_fixture('sample.pdf').open, filename: 'sample.pdf')

    CreateCoversJob.perform_now(book)

    cover = book.reload.cover
    assert cover.attached?
    assert_equal 'image/jpeg', cover.content_type
    assert_equal "\xFF\xD8\xFF".b, cover.download.byteslice(0, 3)
  end

  test "leaves a Word file without a cover" do
    book = books(:english)
    book.attachment.attach(io: StringIO.new('doc'), filename: 'book.doc', content_type: 'application/msword')

    CreateCoversJob.perform_now(book)

    assert_not book.reload.cover.attached?
  end
end
