class AddDownloadCountToPackageVersions < ActiveRecord::Migration[8.1]
  def change
    add_column :package_versions, :download_count, :integer, default: 0
  end
end
