require_relative '../spec_helper'

RSpec.describe 'App-level error handling' do
  describe 'malformed JSON body' do
    it 'returns a JSON 400 when the request body is not valid JSON' do
      post '/api/v1/users', '{ not valid json', 'CONTENT_TYPE' => 'application/json'
      expect(last_response.status).to eq(400)
      expect(json_body['error']).to match(/invalid json/i)
    end
  end

  describe 'unhandled exceptions' do
    # In the test env Sinatra re-raises by default (raise_errors = true), which
    # bypasses the `error` handler. Turn it off so the handler actually runs.
    around do |example|
      KanbanBackend::App.set :raise_errors, false
      example.run
      KanbanBackend::App.set :raise_errors, true
    end

    it 'returns a generic JSON 500 from the global error handler' do
      user = create_user
      allow(User).to receive(:active).and_raise(StandardError, 'boom')

      get '/api/v1/users', {}, auth_for(user)

      expect(last_response.status).to eq(500)
      expect(json_body['error']).to match(/internal server error/i)
    end
  end
end
