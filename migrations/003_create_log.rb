class CreateEntries < Sequel::Migration
  def up
    create_table! :entries do
      primary_key :id

      String :title
      String :url
      Text   :body
      Time   :ctime
    end
  end

  def down
    drop_table :entries
  end
end
