class AddWidgetsAndAssetsToPackageVersions < ActiveRecord::Migration[8.1]
  def change
    add_column :package_versions, :widgets, :json, default: []
    add_column :package_versions, :assets, :json, default: []
  end
end
