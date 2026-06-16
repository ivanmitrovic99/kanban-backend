KanbanBackend::App.controllers :sessions do
  # POST /api/v1/login  { "email": "...", "password": "..." }
  # Returns a JWT the client sends back as: Authorization: Bearer <token>
  post :login, map: Api.path(:login) do
    email = json_params['email'].to_s.downcase.strip
    user  = User.first(email: email)

    if user && user.authenticate(json_params['password'])
      {
        token: issue_token(user),
        user:  user.values.slice(:id, :name, :email)
      }.to_json
    else
      halt 401, { error: 'Invalid email or password' }.to_json
    end
  end

  # POST /api/v1/logout — revoke the caller's current token.
  post :logout, map: Api.path(:logout) do 
    authenticate!
    RevokedToken.create(jti: @token_payload['jti'], expires_at: Time.at(@token_payload['exp']))
    status 204
  end

  # GET /api/v1/me  — example protected route: returns the current user.
  get :me, map: Api.path(:me) do
    @user = authenticate!
    render 'users/show'
  end
end
