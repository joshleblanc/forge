class CreateApiKeys < ActiveRecord::Migration[8.1]
  def change
    create_table :api_keys do |t|
      t.references :user, foreign_key: { on_delete: :nullify }
      t.string :name, null: false
      t.string :key, null: false
      t.integer :download_count, default: 0
      t.integer :publish_count, default: 0
      t.timestamps
    end

    add_index :api_keys, :key, unique: true
  end
end
