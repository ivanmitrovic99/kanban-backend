# RABL relies on ActiveSupport's Array#extract_options!; load just that core ext.
require 'active_support/core_ext/array/extract_options'
require 'rabl'

# Register RABL as a Tilt template engine and apply project-wide defaults.
Rabl.register!
Rabl.configure do |config|
  config.include_json_root  = false
  config.include_child_root = false
  config.view_paths         = [Padrino.root('app', 'views')]
end

module KanbanBackend
  class App < Padrino::Application
    register Padrino::Mailer
    register Padrino::Helpers

    # Stateless JSON API: no sessions, no CSRF token exchange.
    disable :sessions
    disable :protect_from_csrf

    # This is a JSON API: render every response as JSON and parse JSON bodies.
    before do
      content_type :json
    end

    not_found do
      content_type :json
      { error: 'Not found' }.to_json
    end

    error do
      err = env['sinatra.error']                       
      logger.error "#{err.class}: #{err.message}" if err
      logger.error err.backtrace.join("\n") if err     
      content_type :json
      status 500
      { error: 'Internal server error' }.to_json       
    end

    # Make a parsed JSON request body available to controllers as `json_params`.
    helpers do
      def json_params
        return {} if request.body.nil?

        body = request.body.read
        request.body.rewind
        return {} if body.strip.empty?

        JSON.parse(body)
      rescue JSON::ParserError
        halt 400, { error: 'Invalid JSON body' }.to_json
      end
    end

    ##
    # Caching support.
    #
    # register Padrino::Cache
    # enable :caching
    #
    # You can customize caching store engines:
    #
    # set :cache, Padrino::Cache.new(:LRUHash) # Keeps cached values in memory
    # set :cache, Padrino::Cache.new(:Memcached) # Uses default server at localhost
    # set :cache, Padrino::Cache.new(:Memcached, server: '127.0.0.1:11211', exception_retry_limit: 1)
    # set :cache, Padrino::Cache.new(:Memcached, backend: memcached_or_dalli_instance)
    # set :cache, Padrino::Cache.new(:Redis) # Uses default server at localhost
    # set :cache, Padrino::Cache.new(:Redis, host: '127.0.0.1', port: 6379, db: 0)
    # set :cache, Padrino::Cache.new(:Redis, backend: redis_instance)
    # set :cache, Padrino::Cache.new(:Mongo) # Uses default server at localhost
    # set :cache, Padrino::Cache.new(:Mongo, backend: mongo_client_instance)
    # set :cache, Padrino::Cache.new(:File, dir: Padrino.root('tmp', app_name.to_s, 'cache')) # default choice
    #

    ##
    # Application configuration options.
    #
    # set :raise_errors, true       # Raise exceptions (will stop application) (default for test)
    set :dump_errors, true        # Exception backtraces are written to STDERR (default for production/development)
    set :show_exceptions, false    # Shows a stack trace in browser (default for development)
    # set :logging, true            # Logging in STDOUT for development and file for production (default only for development)
    # set :public_folder, 'foo/bar' # Location for static assets (default root/public)
    # set :reload, false            # Reload application files (default in development)
    # set :default_builder, 'foo'   # Set a custom form builder (default 'StandardFormBuilder')
    # set :locale_path, 'bar'       # Set path for I18n translations (default your_apps_root_path/locale)
    # disable :sessions             # Disabled sessions by default (enable if needed)
    # disable :flash                # Disables sinatra-flash (enabled by default if Sinatra::Flash is defined)
    # layout  :my_layout            # Layout can be in views/layouts/foo.ext or views/foo.ext (default :application)
    #

    ##
    # You can configure for a specified environment like:
    #
    #   configure :development do
    #     set :foo, :bar
    #     disable :asset_stamp # no asset timestamping for dev
    #   end
    #

    ##
    # You can manage errors like:
    #
    #   error 404 do
    #     render 'errors/404'
    #   end
    #
    #   error 500 do
    #     render 'errors/500'
    #   end
    #
  end
end
