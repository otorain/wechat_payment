
module WechatPayment
  class Service
    attr_reader :client, :payment_order

    def initialize(payment_order)
      @client = WechatPayment::Client.new
      @payment_order = payment_order
    end

    # 下单
    def order
      order_result = client.order(payment_order.as_order_params)

      if order_result.success?
        payment_order.payment_apply_success(order_result.data)
      else
        payment_order.payment_apply_failure(order_result.errors)
      end

      order_result
    end

    # 退款
    def refund(refund_fee)
      if !payment_order.balance_enough_to_refund?(refund_fee)
        return WechatPayment::ServiceResult.new(message_type: :error, message: "Balance is not enough.")
      end

      refund_order = payment_order.create_refund_order(refund_fee)
      refund_result = client.refund(refund_order.as_refund_params)

      if refund_result.success?
        refund_order.refund_apply_success(refund_result.data)
      else
        refund_order.refund_apply_failure(refund_result.errors)
      end

      refund_result
    end

    # 处理支付回调
    def self.handle_payment_notify(notify_data)
      result = WechatPayment::Client.handle_payment_notify(notify_data)
      payment_order = WechatPayment::PaymentOrder.find_by(out_trade_no: notify_data["out_trade_no"])

      if result.success? && payment_order.pending_pay?
        payment_order.with_lock do
          payment_order.payment_exec_success(result.data)
        end
      else
        payment_order.payment_exec_failure(result.errors)
      end

      result
    end

    # 处理退款回调
    def self.handle_refund_notify(notify_data)
      result = WechatPayment::Client.handle_refund_notify(notify_data)
      refund_order = WechatPayment::RefundOrder.find_by(out_refund_no: result.data["out_refund_no"])

      if result.success? && refund_order.pending_pay?
        refund_order.with_lock do
          refund_order.refund_exec_success(result.data)
        end
      else
        refund_order.refund_exec_failure(result.errors)
      end

      result
    end
  end
end