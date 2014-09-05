class AddDetectedArchToHost < ActiveRecord::Migration
  def change
    add_column :hosts, :detected_arch, :string, { :null => true, :limit => 32 }
  end
end
