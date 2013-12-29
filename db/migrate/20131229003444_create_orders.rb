class CreateOrders < ActiveRecord::Migration
  def change
    create_table :orders do |t|
      t.string :nick
      t.string :json_blob
      t.boolean :paid

      t.timestamps
    end
  end
end
