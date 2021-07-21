
module WechatPayment
  module Concern
    module OwnedGoods
      def self.included(base)
        base.class_eval do

          has_many :payment_orders, class_name: "WechatPayment::PaymentOrder", as: :goods
          has_many :refund_orders, through: :payment_orders
        end
      end
    end
  end
end