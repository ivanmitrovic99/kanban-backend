# Shared user representation. password_digest is intentionally never exposed.
attributes :id, :name, :created_at, :updated_at, :active

node(:email, if: ->(u) { can_see_email?(u) }) { |u| u.email }