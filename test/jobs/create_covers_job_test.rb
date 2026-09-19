require 'test_helper'

class CreateCoversJobTest < ActiveJob::TestCase
  test "renders page 1 of the PDF as the cover" do
    skip 'needs Ghostscript and ImageMagick' unless system('which gs convert > /dev/null 2>&1')

    book = books(:english)
    book.update!(attachment: file_fixture('sample.pdf').open)

    CreateCoversJob.perform_now(book)

    assert book.reload.cover.present?
    assert File.file?(book.cover.path)
  end
end
