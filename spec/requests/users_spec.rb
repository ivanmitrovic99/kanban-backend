require_relative '../spec_helper'

RSpec.describe 'Users API' do
  describe 'POST /api/v1/users (create)' do
    it 'creates a user and returns 201 without exposing the password' do
      post_json '/api/v1/users', { name: 'Alice', email: 'alice@example.com', password: 'password123' }

      expect(last_response.status).to eq(201)
      expect(json_body).to include('id', 'name' => 'Alice', 'email' => 'alice@example.com')
      expect(json_body.keys).not_to include('password_digest', 'password')
    end

    it 'downcases and strips the email' do
      post_json '/api/v1/users', { name: 'Bob', email: '  BOB@Example.COM ', password: 'password123' }
      expect(json_body['email']).to eq('bob@example.com')
    end

    it 'rejects a missing name with 422' do
      post_json '/api/v1/users', { email: 'x@example.com', password: 'password123' }
      expect(last_response.status).to eq(422)
      expect(json_body['errors'].join).to match(/name/i)
    end

    it 'rejects an invalid email with 422' do
      post_json '/api/v1/users', { name: 'X', email: 'not-an-email', password: 'password123' }
      expect(last_response.status).to eq(422)
      expect(json_body['errors'].join).to match(/email/i)
    end

    it 'rejects a password shorter than 8 characters with 422' do
      post_json '/api/v1/users', { name: 'X', email: 'x@example.com', password: 'short' }
      expect(last_response.status).to eq(422)
      expect(json_body['errors'].join).to match(/password/i)
    end

    it 'rejects a duplicate email among active users with 422' do
      create_user(email: 'dup@example.com')
      post_json '/api/v1/users', { name: 'X', email: 'dup@example.com', password: 'password123' }
      expect(last_response.status).to eq(422)
    end

    it 'allows reusing the email of a soft-deleted user' do
      create_user(email: 'reuse@example.com').update(active: false)
      post_json '/api/v1/users', { name: 'New', email: 'reuse@example.com', password: 'password123' }
      expect(last_response.status).to eq(201)
    end
  end

  describe 'GET /api/v1/users (index)' do
    it 'requires authentication' do
      get '/api/v1/users'
      expect(last_response.status).to eq(401)
    end

    it 'lists only active users when authenticated' do
      viewer   = create_user(email: 'active@example.com')
      create_user(email: 'inactive@example.com').update(active: false)

      get '/api/v1/users', {}, auth_for(viewer)

      expect(last_response.status).to eq(200)
      emails = json_body['data'].map { |u| u['email'] }
      expect(emails).to include('active@example.com')
      expect(emails).not_to include('inactive@example.com')
    end

    it 'paginates with per_page and page (distinct pages)' do
      viewer = create_user(email: 'viewer@example.com')
      4.times { |i| create_user(email: "p#{i}@example.com") }

      get '/api/v1/users', { per_page: 2, page: 1 }, auth_for(viewer)
      expect(last_response.status).to eq(200)
      expect(json_body['data'].size).to eq(2)
      page1_ids = json_body['data'].map { |u| u['id'] }

      get '/api/v1/users', { per_page: 2, page: 2 }, auth_for(viewer)
      page2_ids = json_body['data'].map { |u| u['id'] }

      expect(page2_ids).not_to eq(page1_ids)
      expect(page1_ids & page2_ids).to be_empty
    end
  end

  describe 'GET /api/v1/users/:id (show)' do
    it 'requires authentication' do
      user = create_user
      get "/api/v1/users/#{user.id}"
      expect(last_response.status).to eq(401)
    end

    it 'returns the user for a valid id when authenticated' do
      user = create_user(email: 'show@example.com')
      get "/api/v1/users/#{user.id}", {}, auth_for(user)
      expect(last_response.status).to eq(200)
      expect(json_body['email']).to eq('show@example.com')
    end

    it 'returns 404 for a non-integer id' do
      viewer = create_user
      get '/api/v1/users/abc', {}, auth_for(viewer)
      expect(last_response.status).to eq(404)
    end

    it 'returns 404 for a missing id' do
      viewer = create_user
      get '/api/v1/users/999999', {}, auth_for(viewer)
      expect(last_response.status).to eq(404)
    end

    it 'returns 404 for a soft-deleted user' do
      viewer = create_user(email: 'viewer@example.com')
      gone   = create_user(email: 'gone@example.com')
      gone.update(active: false)
      get "/api/v1/users/#{gone.id}", {}, auth_for(viewer)
      expect(last_response.status).to eq(404)
    end
  end

  describe 'PUT/PATCH /api/v1/users/:id (update)' do
    it 'requires authentication' do
      user = create_user
      put_json "/api/v1/users/#{user.id}", { name: 'New' }
      expect(last_response.status).to eq(401)
    end

    it "forbids updating another user's record with 403" do
      owner = create_user(email: 'owner@example.com')
      other = create_user(email: 'other@example.com')
      put_json "/api/v1/users/#{other.id}", { name: 'Hacked' }, auth_for(owner)
      expect(last_response.status).to eq(403)
    end

    it 'updates own record via PUT with partial (PATCH-style) semantics' do
      user = create_user(name: 'Before', email: 'put@example.com')
      put_json "/api/v1/users/#{user.id}", { name: 'After' }, auth_for(user)
      expect(last_response.status).to eq(200)
      expect(json_body['name']).to eq('After')
      expect(json_body['email']).to eq('put@example.com') # untouched field preserved
    end

    it 'updates own record via PATCH' do
      user = create_user(name: 'Before', email: 'patch@example.com')
      patch_json "/api/v1/users/#{user.id}", { name: 'Patched' }, auth_for(user)
      expect(last_response.status).to eq(200)
      expect(json_body['name']).to eq('Patched')
    end

    it 'returns 422 for invalid data' do
      user = create_user(email: 'inv@example.com')
      put_json "/api/v1/users/#{user.id}", { email: 'bad' }, auth_for(user)
      expect(last_response.status).to eq(422)
    end

    it 'returns 404 for a non-integer id (guarded before auth)' do
      put_json '/api/v1/users/abc', { name: 'X' }
      expect(last_response.status).to eq(404)
    end
  end

  describe 'DELETE /api/v1/users/:id (destroy)' do
    it 'requires authentication' do
      user = create_user
      delete "/api/v1/users/#{user.id}"
      expect(last_response.status).to eq(401)
    end

    it "forbids deleting another user's record with 403" do
      owner = create_user(email: 'o@example.com')
      other = create_user(email: 'p@example.com')
      delete "/api/v1/users/#{other.id}", {}, auth_for(owner)
      expect(last_response.status).to eq(403)
    end

    it 'soft-deletes own record (204) and then 404s on show' do
      viewer = create_user(email: 'viewer-del@example.com')
      user   = create_user(email: 'del@example.com')

      delete "/api/v1/users/#{user.id}", {}, auth_for(user)
      expect(last_response.status).to eq(204)
      expect(User[user.id].active).to be(false)

      # A still-active viewer (the deleted user's own token is now rejected).
      get "/api/v1/users/#{user.id}", {}, auth_for(viewer)
      expect(last_response.status).to eq(404)
    end

    it 'returns 422 when the soft-delete fails to save' do
      user = create_user(email: 'failsave@example.com')
      allow_any_instance_of(User).to receive(:update).and_return(false)

      delete "/api/v1/users/#{user.id}", {}, auth_for(user)

      expect(last_response.status).to eq(422)
    end
  end
end
