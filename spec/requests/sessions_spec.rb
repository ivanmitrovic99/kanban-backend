require_relative '../spec_helper'

RSpec.describe 'Sessions / Auth API' do
  describe 'POST /api/v1/login' do
    it 'returns a token and the user for valid credentials' do
      create_user(email: 'login@example.com')
      post_json '/api/v1/login', { email: 'login@example.com', password: 'password123' }

      expect(last_response.status).to eq(200)
      expect(json_body).to include('token')
      expect(json_body['user']).to include('email' => 'login@example.com')
      expect(json_body['user'].keys).not_to include('password_digest')
    end

    it 'is case-insensitive on the email' do
      create_user(email: 'case@example.com')
      post_json '/api/v1/login', { email: 'CASE@EXAMPLE.COM', password: 'password123' }
      expect(last_response.status).to eq(200)
    end

    it 'rejects a wrong password with 401' do
      create_user(email: 'wrong@example.com')
      post_json '/api/v1/login', { email: 'wrong@example.com', password: 'nope' }
      expect(last_response.status).to eq(401)
    end

    it 'rejects an unknown email with 401' do
      post_json '/api/v1/login', { email: 'ghost@example.com', password: 'password123' }
      expect(last_response.status).to eq(401)
    end
  end

  describe 'GET /api/v1/me' do
    it 'returns the current user with a valid token' do
      user = create_user(email: 'me@example.com')
      get '/api/v1/me', {}, auth_for(user)
      expect(last_response.status).to eq(200)
      expect(json_body['email']).to eq('me@example.com')
    end

    it 'rejects a missing token with 401' do
      get '/api/v1/me'
      expect(last_response.status).to eq(401)
    end

    it 'rejects an expired token with 401' do
      user  = create_user
      token = forge_token(user_id: user.id, exp: Time.now.to_i - 60)
      get '/api/v1/me', {}, auth_header(token)
      expect(last_response.status).to eq(401)
      expect(json_body['error']).to match(/expired/i)
    end

    it 'rejects a token with a tampered signature with 401' do
      user  = create_user
      token = "#{forge_token(user_id: user.id)}tampered"
      get '/api/v1/me', {}, auth_header(token)
      expect(last_response.status).to eq(401)
    end

    it 'rejects a structurally-valid token signed with the wrong secret' do
      user    = create_user
      payload = { user_id: user.id, exp: Time.now.to_i + 3600,
                  iss: 'kanban-backend', aud: 'kanban-api', jti: SecureRandom.uuid }
      token   = JWT.encode(payload, 'a-completely-different-secret', 'HS256')

      get '/api/v1/me', {}, auth_header(token)

      expect(last_response.status).to eq(401)
      expect(json_body['error']).to match(/signature/i)
    end

    it 'rejects a token with the wrong audience' do
      user  = create_user
      token = forge_token(user_id: user.id, aud: 'someone-else')
      get '/api/v1/me', {}, auth_header(token)
      expect(last_response.status).to eq(401)
    end

    it 'rejects a token with the wrong issuer' do
      user  = create_user
      token = forge_token(user_id: user.id, iss: 'evil-service')
      get '/api/v1/me', {}, auth_header(token)
      expect(last_response.status).to eq(401)
    end

    it 'rejects a token belonging to a soft-deleted user' do
      user  = create_user
      token = forge_token(user_id: user.id)
      user.update(active: false)
      get '/api/v1/me', {}, auth_header(token)
      expect(last_response.status).to eq(401)
    end
  end

  describe 'POST /api/v1/logout (revocation)' do
    it 'revokes the token: 204, then the same token is rejected as revoked' do
      user    = create_user(email: 'logout@example.com')
      headers = auth_header(forge_token(user_id: user.id))

      get '/api/v1/me', {}, headers
      expect(last_response.status).to eq(200)

      post '/api/v1/logout', {}, headers
      expect(last_response.status).to eq(204)

      get '/api/v1/me', {}, headers
      expect(last_response.status).to eq(401)
      expect(json_body['error']).to match(/revoked/i)
    end

    it 'is safe to call twice (second call returns 401, not 500)' do
      user    = create_user
      headers = auth_header(forge_token(user_id: user.id))

      post '/api/v1/logout', {}, headers
      expect(last_response.status).to eq(204)

      post '/api/v1/logout', {}, headers
      expect(last_response.status).to eq(401)
    end
  end

  describe 'rate limiting on POST /api/v1/login' do
    it 'returns 429 after 5 attempts from the same IP in the window' do
      create_user(email: 'rl@example.com')

      5.times do
        post_json '/api/v1/login', { email: 'rl@example.com', password: 'wrong' }
        expect(last_response.status).to eq(401)
      end

      post_json '/api/v1/login', { email: 'rl@example.com', password: 'wrong' }
      expect(last_response.status).to eq(429)
    end
  end
end
