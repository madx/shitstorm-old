class SplitLog < Sequel::Migration
  def up
    alter_table :comments do
      add_foreign_key :entry_id, :entries
    end

    alter_table :entries do
      drop_column :url
      add_column  :author, String
    end

    alter_table :issues do
      rename_column :description, :body
    end
  end

  def down
    alter_table :comments do
      drop_column :entry_id
    end

    alter_table :entries do
      add_column  :url, String
      drop_column :author
    end

    alter_table :issues do
      rename_column :body, :description
    end
  end
end
