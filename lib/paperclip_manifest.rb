require "csv"
require "digest/md5"
require "net/http"

# Builds the manifest the Active Storage backfill reads: one row per Paperclip
# file, with the size and MD5 checksum Active Storage needs for a blob. It only
# reads, and never writes to the bucket.
#
# With a source URL (the public bucket's base URL) it streams every object over
# plain HTTPS, so it needs no credentials. With a source directory it reads the
# files Paperclip stored locally under the same keys. A rerun keeps the rows of
# files that have not changed since, so refreshing the manifest only reads new
# and changed books.
#
# It uses only the Paperclip columns, not Paperclip itself, so it still runs
# once Book has moved to Active Storage.
class PaperclipManifest
  HEADERS = %w[book_id name key filename content_type byte_size checksum updated_at error].freeze
  ATTACHMENTS = %w[attachment cover].freeze

  def initialize(path, source_url: nil, source_dir: nil, io: $stdout)
    raise ArgumentError, "give a source_url or a source_dir" unless source_url || source_dir

    @path = Pathname(path)
    @source_url = source_url&.delete_suffix("/")
    @source_dir = source_dir && Pathname(source_dir)
    @io = io
  end

  def run
    previous = read_previous
    stats = Hash.new(0)

    rows = []
    Book.find_each.with_index(1) do |book, index|
      ATTACHMENTS.each do |name|
        next if book.public_send("#{name}_file_name").blank?

        row = previous_row(book, name, previous)
        if row
          stats[:reused] += 1
        else
          row = read_row(book, name)
          stats[row["error"] ? :failed : :read] += 1
        end
        rows << row
      end
      @io.puts "#{index} books, #{stats.inspect}" if (index % 100).zero?
    end

    write(rows)
    @io.puts "Wrote #{rows.size} rows to #{@path}: #{stats[:read]} read, #{stats[:reused]} unchanged, #{stats[:failed]} failed"
    stats
  end

  # Paperclip's default S3 path, ":class/:attachment/:id_partition/:style/:filename".
  # The cover's :original style converts to JPEG, so a cover recorded as
  # cover.png is stored as cover.jpg.
  def self.key_for(book, name)
    file_name = book.public_send("#{name}_file_name")
    file_name = "#{File.basename(file_name, '.*')}.jpg" if name == "cover"
    partition = format("%09d", book.id).scan(/\d{3}/).join("/")
    "books/#{name.pluralize}/#{partition}/original/#{file_name}"
  end

  def url_for(key)
    "#{@source_url}/#{key.split('/').map { |segment| ERB::Util.url_encode(segment) }.join('/')}"
  end

  private

  # The existing row, if its key and timestamp still match and it was read fine.
  def previous_row(book, name, previous)
    row = previous[[book.id.to_s, name]]
    row if row && row["error"].blank? &&
      row["key"] == self.class.key_for(book, name) && row["updated_at"] == updated_at(book, name)
  end

  def read_row(book, name)
    key = self.class.key_for(book, name)
    {
      "book_id" => book.id.to_s,
      "name" => name,
      "key" => key,
      # The key's basename rather than the *_file_name column, for the covers.
      "filename" => File.basename(key),
      "updated_at" => updated_at(book, name)
    }.merge(@source_url ? read_remote(key) : read_local(key))
  end

  def read_local(key)
    file = @source_dir.join(key)
    return { "error" => "missing" } unless file.file?

    {
      "content_type" => Marcel::MimeType.for(file, name: file.basename.to_s),
      "byte_size" => File.size(file).to_s,
      "checksum" => Digest::MD5.file(file).base64digest
    }
  end

  def read_remote(key)
    uri = URI(url_for(key))
    md5 = Digest::MD5.new
    size = 0
    result = nil

    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 10, read_timeout: 60) do |http|
      http.request_get(uri) do |response|
        unless response.is_a?(Net::HTTPSuccess)
          result = { "error" => "HTTP #{response.code}" }
          next
        end

        response.read_body do |chunk|
          md5 << chunk
          size += chunk.bytesize
        end
        result = { "content_type" => response.content_type, "byte_size" => size.to_s, "checksum" => md5.base64digest }
      end
    end
    result
  rescue IOError, SystemCallError, Timeout::Error, OpenSSL::SSL::SSLError, Net::ProtocolError => e
    { "error" => "#{e.class}: #{e.message}" }
  end

  def updated_at(book, name)
    book.public_send("#{name}_updated_at")&.utc&.iso8601(6).to_s
  end

  def read_previous
    return {} unless @path.file?

    CSV.foreach(@path, headers: true).to_h { |row| [[row["book_id"], row["name"]], row.to_h] }
  end

  # Write to a temporary file first, so an interrupted run keeps the old manifest.
  def write(rows)
    tmp = @path.sub_ext(".tmp#{@path.extname}")
    CSV.open(tmp, "w", write_headers: true, headers: HEADERS) do |csv|
      rows.each { |row| csv << row.values_at(*HEADERS) }
    end
    File.rename(tmp, @path)
  end
end
