Sequel.migration do
  up do
    alter_table :users do
      add_column :active, :boolean, default: true, null: false
    end
  end

  down do
    alter_table :users do
      drop_column :active
    end
  end
end
