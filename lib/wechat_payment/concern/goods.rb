
module WechatPayment
  module Concern
    module Goods
      extend ActiveSupport::Concern


      def self.included(base)
        base.class_eval do
          cattr_accessor :user_model, :user_ref_field, :goods_ref_field, :user_goods_model, :persist_goods_attrs

          self.user_model = "User"
          self.user_ref_field = "user"
          self.goods_ref_field = self.name.underscore
          self.persist_goods_attrs = []

          # 商品和用户的中间表模型，假设商品模型是 Product，那么中间模型就是 UserProduct
          self.user_goods_model = "#{self.user_model}#{self.name}"

          validates_numericality_of :price
          validates_presence_of :name
        end
      end

      # 售出
      # @param [User] user
      # @return [WechatPaymentOrder]
      def sell_to(user, with_info = {})
        persist_goods_data = {}.tap do |h|
          self.class.persist_goods_attrs.each do |attr|
            h[attr] = send(attr)
          end
        end

        user_goods_model = self.class.user_goods_model.constantize

        user_goods = user_goods_model.new(
          self.class.goods_ref_field => self,
          self.class.user_ref_field => user,
          **with_info,
          **persist_goods_data,
        )

        unless user_goods.save
          return WechatPayment::ServiceResult.new(success: false,
                                                  error: user_goods.errors,
                                                  message: "商品中间表 #{user_goods_model.table_name} 插入数据失败",
                                                  error_type: :create_user_goods_failed)
        end

        payment_order = user_goods.payment_orders.new(
          body: name,
          total_fee: price,
          trade_type: :JSAPI,
          customer: user
        )

        unless payment_order.save
          return WechatPayment::ServiceResult.new(success: false, error: user_goods.errors, message: "支付订单创建失败")
        end

      end

      # 重新支付，应用场景是： 用户取消了支付后，使用最后一张订单进行支付
      # @return [WechatPayment::ServiceResult]
      # def repay
      #   # 如果不是待支付状态
      #   unless pending?
      #     WechatPayment::ServiceResult.new(message: "当前状态不可支付")
      #   end

        # result = payment_orders.last.repay

      #   if result.success?
      #     WechatPayment::ServiceResult.new(success: true, data: result.data[:js_payload])
      #   else
      #     WechatPayment::ServiceResult.new(message: result.errors.first[:err_code_des])
      #   end
      # end


      # 退款
      # @param [Integer] refund_fee
      # @return [WechatPayment::ServiceResult]
      def refund(refund_fee)
        payment_orders.paid.last.refund(refund_fee)
      end

      def payment_exec_success(payment_order)

      end
    end
  end
end