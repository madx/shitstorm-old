class CreateEvents < Sequel::Migration
  def up
    create_table! :events do
      primary_key :id
      String      :url
      foreign_key :issue_id, :issues
      foreign_key :entry_id, :entries
      String      :message
    end
  end

  def down
    drop_table :events
  end
end
