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
    self.role ||= 'member'
    super
  end

  def admin?
   role == 'admin'
  end

  def validate
    super
    validates_presence %i[name email]
    validates_unique :email do |ds|
      ds.where(active: true)
    end
    validates_format URI::MailTo::EMAIL_REGEXP, :email, message: 'is not a valid email'
    validates_min_length 8, :password, allow_nil: true
    validates_max_length 72, :password, allow_nil: true
    validates_includes %w[member admin], :role
    errors.add(:password, 'is required') if password_digest.nil?
    errors.add(:password, 'cannot be blank') if @password && @password.strip.empty?
  end

  dataset_module do
    def active
      where(active: true)
    end
  end
end
