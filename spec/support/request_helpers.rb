require 'securerandom'

# Shared helpers for request specs: JSON request shortcuts, a user factory,
# and a token minter that mirrors issue_token (so authenticating a request in
# setup doesn't depend on the login endpoint or trip the login rate-limiter).
module RequestHelpers
  JSON_HEADERS     = { 'CONTENT_TYPE' => 'application/json' }.freeze
  DEFAULT_PASSWORD = 'password123'

  # These mirror the app's auth_helper constants. If those change, update here.
  JWT_ISSUER   = 'kanban-backend'
  JWT_AUDIENCE = 'kanban-api'

  # --- JSON request shortcuts (send a JSON-encoded body) -------------------
  def post_json(path, payload = {}, headers = {})
    post path, payload.to_json, JSON_HEADERS.merge(headers)
  end

  def put_json(path, payload = {}, headers = {})
    put path, payload.to_json, JSON_HEADERS.merge(headers)
  end

  def patch_json(path, payload = {}, headers = {})
    patch path, payload.to_json, JSON_HEADERS.merge(headers)
  end

  # --- response ------------------------------------------------------------
  def json_body
    JSON.parse(last_response.body)
  end

  # --- fixtures ------------------------------------------------------------
  def create_user(attrs = {})
    defaults = {
      name: 'Test User',
      email: "user-#{SecureRandom.hex(4)}@example.com",
      password: DEFAULT_PASSWORD
    }
    User.create(defaults.merge(attrs))
  end

  # --- auth ----------------------------------------------------------------
  def forge_token(user_id:, **overrides)
    payload = {
      user_id: user_id,
      exp: Time.now.to_i + 3600,
      iss: JWT_ISSUER,
      aud: JWT_AUDIENCE,
      jti: SecureRandom.uuid
    }.merge(overrides)
    JWT.encode(payload, ENV.fetch('JWT_SECRET'), 'HS256')
  end

  def auth_header(token)
    { 'HTTP_AUTHORIZATION' => "Bearer #{token}" }
  end

  # Convenience: a valid Authorization header for an existing user.
  def auth_for(user)
    auth_header(forge_token(user_id: user.id))
  end
end
