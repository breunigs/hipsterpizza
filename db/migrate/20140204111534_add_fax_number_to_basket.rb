class AddFaxNumberToBasket < ActiveRecord::Migration
  def change
    add_column :baskets, :fax_number, :string
  end
end
