Sequel.migration do
  up do
    alter_table :users do
      add_column :role, String, null: false, default: 'member'
      add_column :confirmed_at, DateTime
      add_column :confirmation_token, String
      add_index :confirmation_token, unique: true
      add_column :confirmation_sent_at, DateTime
      add_column :reset_password_token, String
      add_index :reset_password_token, unique: true
      add_column :reset_password_sent_at, DateTime
      add_column :display_name, String
      add_column :bio, String, text: true
      add_column :avatar_url, String
      add_column :last_login_at, DateTime
      add_column :sign_in_count, Integer, null: false, default: 0
    end
  end

  down do
    alter_table :users do
      drop_column :role
      drop_column :confirmed_at
      drop_index :confirmation_token
      drop_column :confirmation_token
      drop_column :confirmation_sent_at
      drop_index :reset_password_token
      drop_column :reset_password_token
      drop_column :reset_password_sent_at
      drop_column :display_name
      drop_column :bio
      drop_column :avatar_url
      drop_column :last_login_at
      drop_column :sign_in_count
    end
  end
end