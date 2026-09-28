require 'test_helper'

class PaperclipManifestTest < ActiveSupport::TestCase
  setup do
    @book = books(:english)
    @book.update!(attachment: file_fixture('sample.pdf').open)
    @path = Rails.root.join('tmp', "manifest-#{SecureRandom.hex(4)}.csv")
  end

  teardown { FileUtils.rm_f(@path) }

  def run_manifest(**options)
    PaperclipManifest.new(@path, io: StringIO.new, **options).run
  end

  def rows
    CSV.read(@path, headers: true).map(&:to_h)
  end

  test "records the Paperclip key, size and MD5 of each local file" do
    run_manifest

    row = rows.find { |r| r['book_id'] == @book.id.to_s && r['name'] == 'attachment' }
    fixture = file_fixture('sample.pdf')
    assert_equal "books/attachments/#{@book.attachment.path.split('/attachments/').last}", row['key']
    assert_equal 'sample.pdf', row['filename']
    assert_equal 'application/pdf', row['content_type']
    assert_equal fixture.size.to_s, row['byte_size']
    assert_equal Digest::MD5.file(fixture).base64digest, row['checksum']
    assert_nil row['error']
  end

  test "keys a cover by its stored JPEG name, not the recorded one" do
    @book.update_columns(cover_file_name: 'cover.png', cover_content_type: 'image/png',
                         cover_file_size: 1, cover_updated_at: Time.current)
    run_manifest

    row = rows.find { |r| r['book_id'] == @book.id.to_s && r['name'] == 'cover' }
    assert row['key'].end_with?('/original/cover.jpg'), row['key']
    assert_equal 'cover.jpg', row['filename']
  end

  test "records a missing file as an error" do
    FileUtils.rm(@book.attachment.path)
    run_manifest

    row = rows.find { |r| r['book_id'] == @book.id.to_s && r['name'] == 'attachment' }
    assert_equal 'missing', row['error']
    assert_nil row['checksum']
  end

  test "a rerun only reads files that changed" do
    assert_equal 1, run_manifest[:read]
    assert_equal({ reused: 1 }, run_manifest.to_h)

    @book.update_columns(attachment_updated_at: 1.minute.from_now)
    assert_equal({ read: 1 }, run_manifest.to_h)
  end

  test "escapes each key segment for the source URL" do
    manifest = PaperclipManifest.new(@path, source_url: 'https://bucket.example/')
    assert_equal 'https://bucket.example/books/attachments/000/000/003/original/%D8%A7%D9%BA%20%282014%29.pdf',
                 manifest.url_for('books/attachments/000/000/003/original/اٺ (2014).pdf')
  end
end
