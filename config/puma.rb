threads_count = Integer(ENV['RAILS_MAX_THREADS'] || 5)
threads threads_count, threads_count

# Cluster mode only in production. In development it hangs on shutdown and
# gains nothing.
if ENV['RAILS_ENV'] == 'production'
  workers Integer(ENV['WEB_CONCURRENCY'] || 2)
  preload_app!
end

# Run Solid Queue's supervisor inside Puma, so jobs need no separate process.
# Production turns it on in config/deploy.yml; development always runs it.
if ENV['SOLID_QUEUE_IN_PUMA'] || ENV.fetch('RAILS_ENV', 'development') == 'development'
  plugin :solid_queue
end

port        ENV['PORT']     || 3000
environment ENV['RACK_ENV'] || 'development'
pidfile     ENV['PIDFILE']  || 'tmp/pids/server.pid'
