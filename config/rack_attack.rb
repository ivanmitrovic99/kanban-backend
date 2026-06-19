require 'active_support/cache'

# TO DO: REDIS HERE
Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

Rack::Attack.throttle('login/ip', limit: 5, period: 60) do |req|
  req.ip if req.post? && req.path == '/api/v1/login'
end

Rack::Attack.throttle('signup/ip', limit: 3, period: 60) do |req|
  req.ip if req.post? && req.path == '/api/v1/users'
end

Rack::Attack.throttled_responder = lambda do |req|
  [429, { 'Content-Type' => 'application/json' },
   [{ error: 'Too many requests. Try again later.' }.to_json]]
end


