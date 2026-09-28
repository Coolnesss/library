require 'test_helper'

class PaperclipBackfillTest < ActiveSupport::TestCase
  # Where the tests' Paperclip uploads live; see paperclip_defaults in config/environments/test.rb.
  SOURCE_DIR = Rails.root.join('tmp', 'test_uploads')

  setup do
    @book = books(:english)
    @book.update!(attachment: file_fixture('sample.pdf').open)
    @manifest = Rails.root.join('tmp', "manifest-#{SecureRandom.hex(4)}.csv")
    PaperclipManifest.new(@manifest, io: StringIO.new).run
    @key = CSV.read(@manifest, headers: true).find { |r| r['book_id'] == @book.id.to_s }['key']
    ActiveStorage::Blob.service.delete(@key) # left over from an earlier run
  end

  teardown { FileUtils.rm_f(@manifest) }

  def backfill(**options)
    PaperclipBackfill.new(@manifest, io: StringIO.new, **options).run
  end

  def attachment
    ActiveStorage::Attachment.find_by(record_type: 'Book', record_id: @book.id, name: 'attachment')
  end

  test "attaches a blob under the Paperclip key and copies the file" do
    assert_equal({ attached: 1 }, backfill(source_dir: SOURCE_DIR).to_h)

    blob = attachment.blob
    assert_equal @key, blob.key
    assert_equal 'sample.pdf', blob.filename.to_s
    assert_equal 'application/pdf', blob.content_type
    assert blob.analyzed?
    assert_equal file_fixture('sample.pdf').binread, blob.download
  end

  test "without a source dir it only records the blob, for files already in the bucket" do
    backfill

    assert_equal @key, attachment.blob.key
    assert_not attachment.blob.service.exist?(@key)
  end

  test "a rerun changes nothing" do
    backfill(source_dir: SOURCE_DIR)

    assert_no_difference -> { ActiveStorage::Blob.count } do
      assert_equal({ already_attached: 1 }, backfill(source_dir: SOURCE_DIR).to_h)
    end
  end

  test "a dry run only counts" do
    assert_no_difference -> { ActiveStorage::Attachment.count } do
      assert_equal({ would_attach: 1 }, backfill(source_dir: SOURCE_DIR, dry_run: true).to_h)
    end
  end

  test "skips rows it cannot use" do
    FileUtils.rm(@book.attachment.path)
    assert_equal({ source_missing: 1 }, backfill(source_dir: SOURCE_DIR).to_h)

    @book.book_categories.delete_all
    @book.destroy!
    assert_equal({ book_gone: 1 }, backfill.to_h)
  end
end
