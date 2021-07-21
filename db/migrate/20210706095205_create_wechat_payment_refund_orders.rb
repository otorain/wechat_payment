class CreateWechatPaymentRefundOrders < ActiveRecord::Migration[6.1]
  def change
    create_table :wechat_payment_refund_orders do |t|
      t.integer :payment_order_id
      t.integer :refund_fee
      t.integer :total_fee
      t.string :out_trade_no
      t.string :out_refund_no
      t.string :refund_id
      t.string :state
      t.datetime :refunded_at

      t.timestamps

      t.index :payment_order_id, name: "payment_id_on_refund_orders"
    end
  end
end
