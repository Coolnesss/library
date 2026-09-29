# Moving the Paperclip files to Active Storage. Not named paperclip.rake:
# kt-paperclip's railtie loads "tasks/paperclip.rake" from the load path, which
# would pick up a file of that name here instead of its own.
namespace :paperclip do
  manifest_path = -> { ENV["MANIFEST"].presence || Rails.root.join("storage/paperclip_manifest.csv") }

  desc "Write the Active Storage backfill manifest (read-only). " \
       "MANIFEST=path (default storage/paperclip_manifest.csv), " \
       "SOURCE_URL=public bucket base URL (default: read the files in public/system)"
  task manifest: :environment do
    source_url = ENV["SOURCE_URL"].presence
    PaperclipManifest.new(manifest_path.call, source_url: source_url,
                                              source_dir: (Rails.root.join("public/system") unless source_url)).run
  end

  desc "Create Active Storage blobs and attachments from the manifest, reusing the Paperclip keys. " \
       "MANIFEST=path (default storage/paperclip_manifest.csv), DRY_RUN=1 to only count. " \
       "Copies from public/system when the service is the local disk."
  task backfill: :environment do
    # DiskService is only loaded where it is configured, so not in production.
    local = defined?(ActiveStorage::Service::DiskService) && ActiveStorage::Blob.service.is_a?(ActiveStorage::Service::DiskService)
    PaperclipBackfill.new(manifest_path.call, source_dir: (Rails.root.join("public/system") if local),
                                         dry_run: ENV["DRY_RUN"].present?).run
  end
end
