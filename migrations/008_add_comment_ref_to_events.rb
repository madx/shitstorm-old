class AddCommentRefToEvents < Sequel::Migration
  def up
    alter_table :events do
      add_foreign_key :comment_id, :comments
    end
  end

  def down
    alter_table :events do
      drop_column :comment_id
    end
  end
end
