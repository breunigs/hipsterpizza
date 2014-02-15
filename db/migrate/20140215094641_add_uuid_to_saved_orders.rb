class AddUuidToSavedOrders < ActiveRecord::Migration
  def change
    add_column :saved_orders, :uuid, :string
  end
end
