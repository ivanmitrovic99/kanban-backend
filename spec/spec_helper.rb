# Must start before any application code is loaded, so every line that later
# runs (or doesn't) is tracked. Generates coverage/index.html after the suite.
require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
  add_filter '/config/'
  add_group 'Controllers', 'app/controllers'
  add_group 'Helpers',     'app/helpers'
  add_group 'Models',      'models'
end

RACK_ENV = 'test' unless defined?(RACK_ENV)
require_relative '../config/boot'
Dir[File.expand_path("#{__dir__}/../app/helpers/**/*.rb")].each(&method(:require))
Dir[File.expand_path("#{__dir__}/support/**/*.rb")].each(&method(:require))

RSpec.configure do |conf|
  conf.include Rack::Test::Methods
  conf.include RequestHelpers

  conf.expect_with(:rspec) { |c| c.syntax = :expect }
  conf.disable_monkey_patching!

  # Every example starts from an empty database and a clean rate-limit counter,
  # so order never matters and one spec can't leak state into the next.
  conf.before(:each) do
    User.db.run('TRUNCATE users, revoked_tokens RESTART IDENTITY CASCADE')
    Rack::Attack.cache.store.clear if defined?(Rack::Attack)
  end
end

# Rack app under test (used by Rack::Test::Methods).
def app(app = nil, &blk)
  @app ||= block_given? ? app.instance_eval(&blk) : app
  @app ||= Padrino.application
end
