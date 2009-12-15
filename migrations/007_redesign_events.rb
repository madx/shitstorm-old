class AddForeignKeysToEvents < Sequel::Migration
  def up
    alter_table :events do
      add_column  :code, Integer
      drop_column :message
    end
  end

  def down
    alter_table :events do
      drop_column :code
      add_column  :message, String
    end
  end
end
