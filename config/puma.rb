# config/puma.rb
environment ENV.fetch("RACK_ENV", "development")
port        ENV.fetch("PORT", 3000)

# defaults are fine; no explicit bind needed
# threads 0, 5
# workers ENV.fetch("WEB_CONCURRENCY", 0)
