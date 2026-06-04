KanbanBackend::App.controllers :users do
  # GET /api/v1/users
  get :index, map: Api.path(:users) do
    @users = User.order(:id).all
    render 'users/index'
  end

  # GET /api/v1/users/:id
  get :show, map: Api.path(:users, ':id') do
    @user = User[params[:id]] or halt_not_found
    render 'users/show'
  end

  # POST /api/v1/users
  post :create, map: Api.path(:users) do
    @user = assign_attributes(User.new)
    if @user.save
      status 201
      render 'users/show'
    else
      unprocessable(@user)
    end
  end

  # PUT/PATCH /api/v1/users/:id
  put :update, map: Api.path(:users, ':id') do
    @user = User[params[:id]] or halt_not_found
    if assign_attributes(@user).save
      render 'users/show'
    else
      unprocessable(@user)
    end
  end

  # DELETE /api/v1/users/:id
  delete :destroy, map: Api.path(:users, ':id') do
    user = User[params[:id]] or halt_not_found
    user.destroy
    status 204
    ''
  end

  helpers do
    # Whitelist the writable attributes. `missing: :skip` leaves fields
    # untouched when they are absent from the request body (partial updates).
    def assign_attributes(user)
      user.set_fields(json_params, %w[name email password], missing: :skip)
      user
    end

    def halt_not_found
      halt 404, { error: 'User not found' }.to_json
    end

    def unprocessable(record)
      halt 422, { errors: record.errors.full_messages }.to_json
    end
  end
end
