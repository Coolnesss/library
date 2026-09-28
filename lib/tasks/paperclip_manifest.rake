namespace :paperclip do
  desc "Write the Active Storage backfill manifest (read-only). " \
       "MANIFEST=path (default storage/paperclip_manifest.csv), " \
       "SOURCE_URL=public bucket base URL (default: read local files)"
  task manifest: :environment do
    path = ENV["MANIFEST"].presence || Rails.root.join("storage/paperclip_manifest.csv")
    PaperclipManifest.new(path, source_url: ENV["SOURCE_URL"].presence).run
  end
end
