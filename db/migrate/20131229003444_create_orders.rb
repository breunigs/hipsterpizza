class CreateOrders < ActiveRecord::Migration
  def change
    create_table :orders do |t|
      t.string :nick
      t.string :json
      t.string :uuid
      t.integer :basket_id
      t.boolean :paid, default: false

      t.timestamps
    end
  end
end
