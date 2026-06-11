require 'bcrypt'

class User < Sequel::Model
  plugin :validation_helpers
  # Auto-populate created_at on insert and updated_at on every save.
  plugin :timestamps, update_on_create: true

  # Virtual attribute: assigning a password hashes it into password_digest.
  # The raw password is never persisted.
  def password=(raw)
    @password = raw
    self.password_digest = raw.to_s.empty? ? nil : BCrypt::Password.create(raw)
  end
  attr_reader :password

  # Returns the user on a correct password, otherwise false.
  def authenticate(raw)
    return false if password_digest.nil?

    BCrypt::Password.new(password_digest) == raw && self
  end

  def before_validation
    self.email = email.to_s.downcase.strip unless email.nil?
    super
  end

  def validate
    super
    validates_presence %i[name email]
    validates_unique :email
    validates_format URI::MailTo::EMAIL_REGEXP, :email, message: 'is not a valid email'
    validates_min_length 8, :password, allow_nil: true
    errors.add(:password, 'is required') if password_digest.nil?
  end
end
