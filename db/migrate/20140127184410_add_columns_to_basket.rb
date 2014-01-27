class AddColumnsToBasket < ActiveRecord::Migration
  def change
    add_column :baskets, :shop_url, :string
    add_column :baskets, :uid, :string
    add_column :baskets, :cancelled, :boolean
  end
end
