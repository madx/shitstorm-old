class AddForeignKeysToEvents < Sequel::Migration
  def up
    alter_table :events do
      add_foreign_key :issue_id, :issues
      add_foreign_key :entry_id, :entries
    end
  end

  def down
    alter_table :events do
      drop_column :issue_id
      drop_column :entry_id
    end
  end
end
