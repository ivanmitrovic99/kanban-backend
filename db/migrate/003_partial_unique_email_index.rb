Sequel.migration do
  up do
    alter_table :users do
      drop_index :email
      add_index :email, unique: true, where: { active: true }, name: :users_active_email_index
    end
  end
  down do
    alter_table :users do
      drop_index :email, name: :users_active_email_index
      add_index :email, unique: true
    end
  end
end
  