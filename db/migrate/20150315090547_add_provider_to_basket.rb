class AddProviderToBasket < ActiveRecord::Migration
  def up
    add_column :baskets, :provider, :string
    execute <<-SQL
      UPDATE baskets SET provider = 'pizzade' WHERE provider IS NULL
    SQL
  end

  def down
    remove_column :baskets, :provider
  end
end
