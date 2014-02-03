class AddShaAddressToBasket < ActiveRecord::Migration
  def change
    add_column :baskets, :sha_address, :string
  end
end
