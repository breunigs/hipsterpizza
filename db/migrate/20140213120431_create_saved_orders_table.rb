class CreateSavedOrdersTable < ActiveRecord::Migration
  def change
    create_table :saved_orders do |t|
      t.string :shop_url
      t.string :nick
      t.string :json
      t.string :name
    end
  end
end
