class CreatePackages < ActiveRecord::Migration[8.1]
  def change
    create_table :packages do |t|
      t.string :name, null: false
      t.string :description
      t.string :author, null: false
      t.string :latest_version, default: "1.0.0"
      t.json :tags, default: []
      t.json :scripts, default: []
      t.json :dependencies, default: {}
      t.string :dragonruby_version, default: ">= 3.0"
      t.timestamps
    end

    add_index :packages, :name, unique: true
    add_index :packages, :author
    add_index :packages, :tags, using: 'gin'
  end
end
