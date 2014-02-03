class AddArrivalTimeToBasket < ActiveRecord::Migration
  def change
    add_column :baskets, :arrival, :datetime
  end
end
