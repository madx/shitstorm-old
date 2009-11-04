class CreateIssues < Sequel::Migration
  def up
    create_table! :issues do
      primary_key :id

      String :title
      String :author
      Text   :description
      Time   :ctime
      String :status
    end
  end

  def down
    drop_table :issues
  end
end
