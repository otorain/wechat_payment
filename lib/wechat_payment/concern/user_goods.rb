
module WechatPayment
  module Concern
    module UserGoods
      def self.included(base)
        base.class_eval do

          has_many :payment_orders, as: :goods, class_name: "WechatPayment::PaymentOrder"
          has_many :refund_orders, as: :goods, class_name: "WechatPayment::PaymentOrder"
        end
      end
    end
  end
end