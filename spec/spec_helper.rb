RACK_ENV = 'test' unless defined?(RACK_ENV)
require_relative '../config/boot'
Dir[File.expand_path("#{__dir__}/../app/helpers/**/*.rb")].each(&method(:require))

RSpec.configure do |conf|
  conf.include Rack::Test::Methods
end

# You can use this method to custom specify a Rack app
# you want rack-test to invoke:
#
#   app KanbanBackend::App
#   app KanbanBackend::App.tap { |a| }
#   app(KanbanBackend::App) do
#     set :foo, :bar
#   end
#
def app(app = nil, &blk)
  @app ||= block_given? ? app.instance_eval(&blk) : app
  @app ||= Padrino.application
end
