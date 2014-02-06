class AddDefaultValueToCancelledAttribue < ActiveRecord::Migration
  def up
    change_column :baskets, :cancelled, :boolean, :default => false
  end

  def down
    change_column :baskets, :cancelled, :boolean, :default => nil
  end
end
