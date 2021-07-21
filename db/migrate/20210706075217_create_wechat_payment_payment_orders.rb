class CreateWechatPaymentPaymentOrders < ActiveRecord::Migration[6.1]
  def change
    create_table :wechat_payment_payment_orders do |t|
      t.string :open_id
      t.string :out_trade_no
      t.references :goods, polymorphic: true, null: false
      t.string :transaction_id
      t.string :body
      t.integer :total_fee
      t.string :trade_type
      t.string :spbill_create_ip
      t.string :prepay_id
      t.string :state
      t.datetime :paid_at
      t.datetime :refunded_at

      t.timestamps
    end
    add_index :wechat_payment_payment_orders, :open_id
  end
end
