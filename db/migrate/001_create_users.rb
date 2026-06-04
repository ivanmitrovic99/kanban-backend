Sequel.migration do
  up do
    create_table :users do
      primary_key :id
      String :name, null: false
      String :email, null: false
      String :password_digest, null: false
      DateTime :created_at
      DateTime :updated_at

      index :email, unique: true
    end
  end

  down do
    drop_table :users
  end
end
