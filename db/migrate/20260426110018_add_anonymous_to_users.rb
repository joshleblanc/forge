class AddAnonymousToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :anonymous, :boolean, default: false
    add_index :users, :anonymous
  end
end
