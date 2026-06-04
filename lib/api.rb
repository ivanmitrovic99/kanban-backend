# Single source of truth for the API's mount prefix and version.
#
# Controllers build their routes from Api.path so the version lives in exactly
# one place. Bump VERSION here and every resource (users, boards, cards, ...)
# moves with it.
#
#   Api.path(:users)         # => "/api/v1/users"
#   Api.path(:users, ':id')  # => "/api/v1/users/:id"
module Api
  VERSION = 'v1'
  BASE    = "/api/#{VERSION}".freeze

  def self.path(*segments)
    ['', BASE, *segments].join('/').squeeze('/')
  end
end
