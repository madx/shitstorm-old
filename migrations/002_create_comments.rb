class CreateComments < Sequel::Migration

  def up
    create_table! :comments do
      primary_key :id
      foreign_key :issue_id, :issues

      String :author
      Text   :body
      Time   :ctime
    end
  end

  def down
    drop_table :comments
  end
end
