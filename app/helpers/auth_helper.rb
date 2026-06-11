# App-wide authentication helpers, available in every controller and view.
#
# Flow:
#   1. POST /api/v1/login  -> issue_token(user)  -> { token: "..." }
#   2. Client sends header  Authorization: Bearer <token>  on later requests.
#   3. Protected routes call authenticate! (or read current_user for soft auth).
KanbanBackend::App.helpers do
  JWT_ALGORITHM = 'HS256'.freeze
  TOKEN_TTL     = 24 * 60 * 60 # seconds (24h)

  def jwt_secret
    ENV.fetch('JWT_SECRET')
  end

  # Sign a token carrying the user's id and an expiry.
  def issue_token(user)
    payload = { user_id: user.id, exp: Time.now.to_i + TOKEN_TTL }
    JWT.encode(payload, jwt_secret, JWT_ALGORITHM)
  end

  # Strict guard for protected routes. Halts with a 401 whose message states
  # exactly why the token was rejected, so clients can react (e.g. refresh on
  # expiry vs. re-login on a bad token).
  def authenticate!
    token = bearer_token
    unauthorized!('Missing or malformed Authorization header') unless token

    payload = decode!(token)
    @current_user = User[payload['user_id']]
    unauthorized!('Token refers to a user that no longer exists') unless @current_user

    @current_user
  end

  def authorize_owner!(resource_user_id)
    authenticate!
    halt 403, {error: 'You are not allowed to perform this action'}.to_json unless resource_user_id.to_i == @current_user.id
  end
      
  private

  def bearer_token
    request.env['HTTP_AUTHORIZATION'].to_s[/\ABearer (.+)\z/, 1]
  end

  # Verify + decode, mapping each failure mode to a specific 401.
  def decode!(token)
    JWT.decode(token, jwt_secret, true, algorithm: JWT_ALGORITHM).first
  rescue JWT::ExpiredSignature
    unauthorized!('Token has expired')
  rescue JWT::VerificationError
    unauthorized!('Token signature is invalid')
  rescue JWT::DecodeError
    unauthorized!('Token is malformed')
  end

  # Same decode, but swallow every failure to nil (for current_user).
  def lookup_user(token)
    payload, = JWT.decode(token, jwt_secret, true, algorithm: JWT_ALGORITHM)
    User[payload['user_id']]
  rescue JWT::DecodeError
    nil
  end

  def unauthorized!(message)
    halt 401, { error: message }.to_json
  end
end
