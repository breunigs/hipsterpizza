class RenameFaxNumberToShopFax < ActiveRecord::Migration
  def change
    rename_column :baskets, :fax_number, :shop_fax
  end
end
