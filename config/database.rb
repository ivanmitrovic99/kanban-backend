##
# Sequel + PostgreSQL connection configuration.
#
# Credentials are read from environment variables so they can be overridden
# per machine without touching this file. Sensible local defaults are provided.
#
pg_defaults = {
  adapter:  'postgres',
  host:     ENV.fetch('DATABASE_HOST', 'localhost'),
  port:     ENV.fetch('DATABASE_PORT', 5432).to_i,
  user:     ENV.fetch('DATABASE_USER', 'voi'),
  password: ENV.fetch('DATABASE_PASSWORD'), # required; set in .env (see .env.example)
  max_connections: ENV.fetch('DATABASE_POOL', 5).to_i,
  loggers:  [logger],
  sql_log_level: :debug
}

connections = {
  development: pg_defaults.merge(database: 'kanban_backend_development'),
  production:  pg_defaults.merge(database: ENV.fetch('DATABASE_NAME', 'kanban_backend_production')),
  test:        pg_defaults.merge(database: 'kanban_backend_test')
}

# Return nil instead of raising when a save fails validation; controllers
# branch on the boolean result instead of rescuing exceptions.
Sequel::Model.raise_on_save_failure = false

# Establish the connection for the current environment.
Sequel::Model.db = Sequel.connect(connections[Padrino.env])
