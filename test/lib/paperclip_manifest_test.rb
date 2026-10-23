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

  test "takes the checksum from a single-part upload's ETag, not from a multipart one" do
    fixture = file_fixture('sample.pdf')
    md5 = Digest::MD5.file(fixture)
    assert_equal md5.base64digest, PaperclipManifest.etag_checksum(%("#{md5.hexdigest}"))
    assert_nil PaperclipManifest.etag_checksum(%("#{md5.hexdigest}-3"))
    assert_nil PaperclipManifest.etag_checksum(nil)
  end

  test "a remote run asks with HEAD and downloads nothing when the ETag is an MD5" do
    body = file_fixture('sample.pdf').binread
    with_bucket(etag: %("#{Digest::MD5.hexdigest(body)}"), body: body) do |url, gets|
      assert_equal({ read: 1 }, PaperclipManifest.new(@path, source_url: url, io: StringIO.new).run.to_h)
      assert_equal 0, gets.size
    end
    assert_equal [body.bytesize.to_s, Digest::MD5.base64digest(body), 'application/pdf'],
                 row('attachment').values_at('byte_size', 'checksum', 'content_type')
  end

  test "a remote run downloads and hashes an object whose ETag is not an MD5" do
    body = file_fixture('sample.pdf').binread
    with_bucket(etag: '"0123456789abcdef0123456789abcdef-2"', body: body) do |url, gets|
      PaperclipManifest.new(@path, source_url: url, io: StringIO.new).run
      assert_equal 1, gets.size
    end
    assert_equal Digest::MD5.base64digest(body), row('attachment')['checksum']
  end

  private

  # A tiny stand-in for the public bucket: answers HEAD and GET for any key
  # with the given body and ETag, and records the GETs.
  def with_bucket(etag:, body:)
    server = TCPServer.new('127.0.0.1', 0)
    gets = Queue.new
    thread = Thread.new do
      loop do
        client = server.accept
        request = client.gets.to_s
        nil until client.gets.to_s.strip.empty?
        gets << request if request.start_with?('GET')
        headers = "HTTP/1.1 200 OK\r\nContent-Type: application/pdf\r\nContent-Length: #{body.bytesize}\r\nETag: #{etag}\r\nConnection: close\r\n\r\n"
        client.write(request.start_with?('HEAD') ? headers : headers + body)
        client.close
      end
    end
    yield "http://127.0.0.1:#{server.addr[1]}/", gets
  ensure
    thread&.kill
    server&.close
  end
end
