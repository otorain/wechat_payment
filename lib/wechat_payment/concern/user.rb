
module WechatPayment
  module Concern
    module User

      def self.included(base)
        base.class_eval do
          attr_accessor :spbill_create_ip

          has_many :payment_orders, as: :customer, class_name: "WechatPayment::PaymentOrder"
          has_many :refund_orders, as: :customer, class_name: "WechatPayment::RefundOrder"

          alias me itself
        end
      end

      def buy(goods)
        goods.sell_to(me)
      end
    end
  end
end