Sequel.migration do
  up do
    create_table :revoked_tokens do
      primary_key :id
      String :jti, null: false
      DateTime :expires_at, null: false
      DateTime :created_at
      DateTime :updated_at

      index :jti, unique: true
    end
  end
  
  down do
    drop_table :revoked_tokens
  end
end