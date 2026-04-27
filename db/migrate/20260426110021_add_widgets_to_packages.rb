class AddWidgetsToPackages < ActiveRecord::Migration[8.1]
  def change
    add_column :packages, :widgets, :json, default: []
  end
end
