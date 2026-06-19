KanbanBackend::App.controllers :users do

  DEFAULT_PER_PAGE = 20
  MAX_PER_PAGE = 200

  # GET /api/v1/users
  get :index, map: Api.path(:users) do
    authenticate!
    per_page, page = pagination_params
    total = User.active.count
    @users = User.active.order(:id).limit(per_page).offset((page - 1) * per_page).all
    @meta = {
      page: page,
      per_page: per_page,
      total: total,
      total_pages: (total.to_f / per_page).ceil
    }
    render 'users/index'
  end

  # GET /api/v1/users/:id
  get :show, map: Api.path(:users, ':id') do
    authenticate!
    halt 404 unless valid_id?(params[:id])
    @user = User.where(id: params[:id]).active.first or halt 404
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
  # Both verbs share one handler: updates are partial (PATCH semantics) because
  # assign_attributes uses `missing: :skip`, so PUT here also leaves absent
  # fields untouched rather than clearing them.
  put :update, map: Api.path(:users, ':id') do
    update_user
  end

  patch :update, map: Api.path(:users, ':id') do
    update_user
  end

  # DELETE /api/v1/users/:id
  delete :destroy, map: Api.path(:users, ':id') do
    halt 404 unless valid_id?(params[:id])
    authorize_owner!(params[:id])
    @user = User.where(id: params[:id]).active.first or halt 404
    if @user.update(active: false)
      status 204
    else
      unprocessable(@user)
    end
  end

  helpers do
    # Shared PUT/PATCH update handler.
    def update_user
      halt 404 unless valid_id?(params[:id])
      authorize_owner!(params[:id])
      @user = User.where(id: params[:id]).active.first or halt 404
      if assign_attributes(@user).save
        render 'users/show'
      else
        unprocessable(@user)
      end
    end

    # Whitelist the writable attributes. `missing: :skip` leaves fields
    # untouched when they are absent from the request body (partial updates).
    def assign_attributes(user)
      user.set_fields(json_params, %w[name email password], missing: :skip)
      user
    end

    def unprocessable(record)
      halt 422, { errors: record.errors.full_messages }.to_json
    end

    def valid_id?(id)
      Integer(id, 10).positive?
    rescue ArgumentError, TypeError
      false
    end

    def pagination_params
      per_page = params[:per_page].to_i
      per_page = DEFAULT_PER_PAGE if per_page <= 0
      per_page = [per_page, MAX_PER_PAGE].min
      page = [params[:page].to_i, 1].max
      [per_page, page]
    end

  end
end
