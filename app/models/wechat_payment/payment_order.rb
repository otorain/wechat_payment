module WechatPayment
  class PaymentOrder < ApplicationRecord

    has_many :refund_orders
    belongs_to :customer, polymorphic: true

    before_save :set_customer_info
    before_create :gen_out_trade_no
    belongs_to :goods, polymorphic: true

    scope :by_state, ->(state)do
      where(state: state) if state.present?
    end

    enum state: {
      paid: "paid",
      pending_pay: "pending_pay",
      refunded: "refunded",
      failed: "failed"
    }, _default: "pending_pay"

    # 将部分用户信息保存至订单
    def set_customer_info
      self.openid = customer.openid if openid.blank?
      self.spbill_create_ip = customer.spbill_create_ip
    end

    # 生成交易编号
    def gen_out_trade_no
      loop do
        out_trade_no = "#{Time.current.to_i}#{SecureRandom.random_number(999_999_999)}"
        records_count = WechatPayment::PaymentOrder.where(out_trade_no: out_trade_no).count
        if records_count == 0
          self.out_trade_no = out_trade_no
          break
        end
      end
    end

    # 创建退款订单
    def create_refund_order(refund_fee)
      refund_orders.create(
        out_trade_no: out_trade_no,
        refund_fee: refund_fee,
        total_fee: total_fee,
        goods: goods,
        customer: customer
      )
    end

    def as_order_params
      {
        out_trade_no: out_trade_no,
        spbill_create_ip: spbill_create_ip,
        total_fee: total_fee,
        body: body,
        openid: openid
      }
    end

    # 发起支付
    #
    # @return [Hash]
    #
    # return example
    # {
    #   "appId": "wxf89f9547da823dcd",
    #   "package": "prepay_id=wx28180521320799e04f6028c55c31bf0000",
    #   "nonceStr": "62350ff6c414946d0dc4c49b32ad3fd3",
    #   "timeStamp": "1624874721",
    #   "signType": "MD5",
    #   "paySign": "1F5CBC345B86E5DD055F235A22961422",
    #   "orderId": 17
    # }
    def pay(repay: false)
      if payment_params.present? && !repay
        return ServiceResult.new(success: true, data: payment_params, message: "获取支付参数成功")
      end

      order_result = WechatPayment::Service.new(self).order
      if order_result.success?
        payload = WechatPayment::Client.gen_js_pay_payload(order_result.data).merge(orderId: id).with_indifferent_access

        update(payment_params: payload)

        WechatPayment::ServiceResult.new(success: true, data: payload)
      else
        order_result
      end
    end

    # 重新支付订单
    def repay
      gen_out_trade_no
      save
      pay(repay: true)
    end

    # 发起退款
    # @param [Integer] refund_fee 需要退款的金额，单位：分
    def refund(refund_fee = total_fee)
      WechatPayment::Service.new(self).refund(refund_fee)
    end

    # 判断余额是否足够退款
    def balance_enough_to_refund?(refund_fee)
      total_fee - refunded_fee >= refund_fee
    end

    # 已退款的金额(包括正在退款的金额)
    def refunded_fee
      refund_orders.where(state: [:pending_refund, :refunded]).sum(:refund_fee)
    end

    # 实际已退的金额
    def actual_refunded_fee
      refund_orders.where(state: :refunded).sum(:refund_fee)
    end

    # 订单是否可以退款
    def refundable?
      min_refund_fee = 1
      paid? && balance_enough_to_refund?(min_refund_fee)
    end

    # 支付下单成功
    # @param [Hash] result
    #
    # result example:
    #
    # {
    #   "return_code"=>"SUCCESS",
    #   "return_msg"=>"OK",
    #   "result_code"=>"SUCCESS",
    #   "mch_id"=>"12312412312",
    #   "appid"=>"wxc5f26065c6471234",
    #   "sub_mch_id"=>"1525911234",
    #   "sub_appid"=>"wxf89f912345823dcd",
    #   "nonce_str"=>"ZUN2rEf6ATgYU8Lr",
    #   "sign"=>"3A216DB61196CEC63CE282D53FD1833F",
    #   "prepay_id"=>"wx281553565159884f81c452eb3f26b90000",
    #   "trade_type"=>"JSAPI"
    # }
    def payment_apply_success(result)
      update(prepay_id: result["prepay_id"])

      if goods.respond_to? :payment_apply_success
        goods.payment_apply_success(result)
      end

      result
    end

    # 支付下单失败
    # @param [Hash] result
    #
    # result example:
    #
    # {
    #  "return_code"=>"SUCCESS",
    #  "return_msg"=>"OK",
    #  "result_code"=>"FAIL",
    #  "err_code_des"=>"该订单已支付",
    #  "err_code"=>"ORDERPAID",
    #  "mch_id"=>"1363241802",
    #  "appid"=>"wxc5f26065c6471bcf",
    #  "sub_mch_id"=>"1525918291",
    #  "sub_appid"=>"wxf89f9547da823dcd",
    #  "nonce_str"=>"1jWLkg2YZjwnOozl",
    #  "sign"=>"3C80A1C9BD6CFDB7C37CCFCEAAF9E274"
    # }
    def payment_apply_failure(result)
      update(state: :failed)

      if goods.respond_to? :payment_apply_failure
        goods.payment_apply_failure(result)
      end

      result
    end

    # 支付成功(回调结果)
    # @param [Hash] result
    #
    # result example:
    #
    # {
    #   "appid"=>"wxc5e21215c6471bcf",
    #   "bank_type"=>"CMB_CREDIT",
    #   "cash_fee"=>"1",
    #   "fee_type"=>"CNY",
    #   "is_subscribe"=>"N",
    #   "mch_id"=>"144223114",
    #   "nonce_str"=>"026b7ff3433f482f98610a67bbd8e159",
    #   "openid"=>"omf2nv3OgYXBYrNqdx9eUucKy7NQ",
    #   "out_trade_no"=>"1624866836218932068",
    #   "result_code"=>"SUCCESS",
    #   "return_code"=>"SUCCESS",
    #   "sign"=>"442098E6B670B82B88A843CC2A2AB54D",
    #   "sub_appid"=>"wxf89f95121da823dcd",
    #   "sub_is_subscribe"=>"N",
    #   "sub_mch_id"=>"1525911211",
    #   "sub_openid"=>"ogT7J5YddGnll-ippRvJq62Nv8W0",
    #   "time_end"=>"20210628155426",
    #   "total_fee"=>"1",
    #   "trade_type"=>"JSAPI",
    #   "transaction_id"=>"4200001174202106282207291730"
    # }
    def payment_exec_success(result)
      update(
        state: :paid,
        transaction_id: result["transaction_id"],
        paid_at: Time.current,
        payment_params: nil
      )

      if goods.respond_to? :payment_exec_success
        goods.payment_exec_success(result)
      end

      result
    end

    # 支付失败(回调结果)
    # @param [Hash] result
    #
    # result example:
    #
    def payment_exec_failure(result)
      if goods.respond_to? :payment_exec_failure
        goods.payment_exec_failure(result)
      end
    end

    # 判断是否已经全额退款
    def total_fee_refunded?
      refunded_fee >= total_fee
    end
  end
end
