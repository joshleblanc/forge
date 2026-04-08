class AddSamplesToPackages < ActiveRecord::Migration[8.1]
  def change
    add_column :packages, :samples, :text
  end
end
