require 'test_helper'

class PaperclipManifestTest < ActiveSupport::TestCase
  setup do
    @book = books(:english)
    @book.update_columns(attachment_file_name: 'sample.pdf', attachment_content_type: 'application/pdf',
                         attachment_file_size: file_fixture('sample.pdf').size, attachment_updated_at: Time.current)
    @dir = Rails.root.join('tmp', "paperclip-#{SecureRandom.hex(4)}")
    @key = "books/attachments/#{format('%09d', @book.id).scan(/\d{3}/).join('/')}/original/sample.pdf"
    FileUtils.mkdir_p(@dir.join(@key).dirname)
    FileUtils.cp(file_fixture('sample.pdf'), @dir.join(@key))
    @path = @dir.join('manifest.csv')
  end

  teardown { FileUtils.rm_rf(@dir) }

  def run_manifest(**options)
    PaperclipManifest.new(@path, source_dir: @dir, io: StringIO.new, **options).run
  end

  def row(name)
    CSV.read(@path, headers: true).map(&:to_h).find { |r| r['book_id'] == @book.id.to_s && r['name'] == name }
  end

  test "records the Paperclip key, size and MD5 of each local file" do
    run_manifest

    fixture = file_fixture('sample.pdf')
    assert_equal({ 'book_id' => @book.id.to_s, 'name' => 'attachment', 'key' => @key, 'filename' => 'sample.pdf',
                   'content_type' => 'application/pdf', 'byte_size' => fixture.size.to_s,
                   'checksum' => Digest::MD5.file(fixture).base64digest,
                   'updated_at' => @book.attachment_updated_at.utc.iso8601(6), 'error' => nil }, row('attachment'))
  end

  test "keys a cover by its stored JPEG name, not the recorded one" do
    @book.update_columns(cover_file_name: 'cover.png', cover_content_type: 'image/png',
                         cover_file_size: 1, cover_updated_at: Time.current)
    run_manifest

    assert row('cover')['key'].end_with?('/original/cover.jpg'), row('cover')['key']
    assert_equal 'cover.jpg', row('cover')['filename']
  end

  test "records a missing file as an error" do
    FileUtils.rm(@dir.join(@key))
    run_manifest

    assert_equal 'missing', row('attachment')['error']
    assert_nil row('attachment')['checksum']
  end

  test "a rerun only reads files that changed" do
    assert_equal({ read: 1 }, run_manifest.to_h)
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
