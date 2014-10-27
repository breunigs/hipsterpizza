class AddShopUrlParamsToBaskets < ActiveRecord::Migration
  def change
    add_column :baskets, :shop_url_params, :string
  end
end
