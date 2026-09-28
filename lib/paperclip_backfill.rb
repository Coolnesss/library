require "csv"

# Creates an Active Storage blob and attachment for every file in a
# PaperclipManifest, reusing the Paperclip key, so the files themselves stay
# where they are and their old URLs keep working.
#
# In production the files are already in the bucket under those keys, so
# nothing is copied. Pass a source_dir (development, where the service is the
# local disk) to copy each file from there into the service; the upload
# verifies it against the manifest's checksum.
#
# Books that already have the attachment are skipped, so a rerun is safe.
class PaperclipBackfill
  def initialize(manifest, source_dir: nil, dry_run: false, io: $stdout)
    @manifest = Pathname(manifest)
    @source_dir = source_dir && Pathname(source_dir)
    @dry_run = dry_run
    @io = io
  end

  def run
    stats = Hash.new(0)
    CSV.foreach(@manifest, headers: true).with_index(1) do |row, index|
      stats[process(row)] += 1
      @io.puts "#{index} rows, #{stats.inspect}" if (index % 500).zero?
    end
    @io.puts "#{@dry_run ? 'Dry run: ' : ''}#{stats.sort.map { |result, count| "#{count} #{result}" }.join(', ')}"
    stats
  end

  private

  def process(row)
    return :manifest_error if row["error"].present?
    return :book_gone unless Book.exists?(row["book_id"])
    return :already_attached if ActiveStorage::Attachment.exists?(record_type: "Book", record_id: row["book_id"], name: row["name"])

    source = @source_dir&.join(row["key"])
    return :source_missing if source && !source.file?
    return :would_attach if @dry_run

    ActiveRecord::Base.transaction do
      blob = ActiveStorage::Blob.find_by(key: row["key"]) || create_blob(row)
      source&.open("rb") { |file| blob.service.upload(blob.key, file, checksum: blob.checksum) }
      ActiveStorage::Attachment.create!(name: row["name"], record_type: "Book", record_id: row["book_id"], blob: blob)
    end
    :attached
  end

  # Marked identified and analyzed: the manifest already holds the content
  # type, and analyzing would download every file again.
  def create_blob(row)
    ActiveStorage::Blob.create!(
      key: row["key"],
      filename: row["filename"],
      content_type: row["content_type"],
      byte_size: row["byte_size"],
      checksum: row["checksum"],
      metadata: { "identified" => true, "analyzed" => true },
      created_at: row["updated_at"].presence || Time.current
    )
  end
end
