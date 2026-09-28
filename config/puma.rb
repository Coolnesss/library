threads_count = Integer(ENV['RAILS_MAX_THREADS'] || 5)
threads threads_count, threads_count

# Cluster mode only in production. In development it hangs on shutdown and
# gains nothing.
if ENV['RAILS_ENV'] == 'production'
  workers Integer(ENV['WEB_CONCURRENCY'] || 2)
  preload_app!
end

port        ENV['PORT']     || 3000
environment ENV['RACK_ENV'] || 'development'
pidfile     ENV['PIDFILE']  || 'tmp/pids/server.pid'
