
module WechatPayment
  module Concern
    module User

      def self.included(base)
        base.class_eval do
          attr_accessor :spbill_create_ip

          alias me itself

        end
      end

      def buy(goods)
        goods.sell_to(me)
      end
    end
  end
end