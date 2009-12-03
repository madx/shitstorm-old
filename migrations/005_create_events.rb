class CreateEvents < Sequel::Migration
  def up
    create_table! :events do
      primary_key :id
      String      :message
      String      :url
      Time        :ctime
    end
  end

  def down
    drop_table :events
  end
end
