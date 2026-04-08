class CreatePackageVersions < ActiveRecord::Migration[8.1]
  def change
    create_table :package_versions do |t|
      t.references :package, null: false, foreign_key: true
      t.string :version, null: false
      t.string :dragonruby_version, default: ">= 3.0"
      t.json :dependencies, default: {}
      t.json :scripts, default: []
      t.json :tags, default: []
      t.text :source_code
      t.text :description
      t.timestamps
    end

    add_index :package_versions, [:package_id, :version], unique: true
  end
end
