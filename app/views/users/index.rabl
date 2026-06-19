object false

node :data do
  partial('users/attributes',object: @users)
end

node :meta do
  @meta
end