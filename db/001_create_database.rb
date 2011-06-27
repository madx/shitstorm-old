Sequel.migration do
  up do
    create_table(:users) do
      primary_key :id
      String      :name,   :null => false, :unique => true
      String      :token,  :null => false, :size => 40
      TrueClass   :active, :null => false
    end

    create_table(:tickets) do
      primary_key :id
      foreign_key :author_id,   :users
      String      :title,       :null => false
      String      :body,        :null => false, :text => true
      String      :body_markup, :null => false, :text => true
      DateTime    :created_at,  :null => false
      TrueClass   :active,      :null => false
    end

    create_table(:comments) do
      primary_key :id
      foreign_key :ticket_id,   :tickets
      foreign_key :author_id,   :users
      String      :body,        :null => false, :text => true
      String      :body_markup, :null => false, :text => true
      DateTime    :created_at,  :null => false
    end

    create_table(:updates) do
      primary_key :id
      foreign_key :ticket_id,  :tickets
      foreign_key :author_id,   :users
      TrueClass   :active,     :null => false
      DateTime    :created_at, :null => false
    end
  end

  down do
    drop_table :users
    drop_table :tickets
    drop_table :comments
  end
end
