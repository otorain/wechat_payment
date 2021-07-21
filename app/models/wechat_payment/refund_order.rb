module WechatPayment
  class RefundOrder < ApplicationRecord
    belongs_to :payment_order

    before_create :gen_out_refund_no

    has_one :goods, through: :payment_order, source_type: "Goods"
    enum state: {
      pending: "pending",
      refunded: "refunded",
      failed: "failed"
    }, _default: :pending

    # 生成退款编号
    def gen_out_refund_no
      loop do
        out_refund_no = "#{Time.current.to_i}#{SecureRandom.random_number(999_999_999)}"
        record = WechatPayment::RefundOrder.find_by(out_refund_no: out_refund_no)

        if record.blank?
          self.out_refund_no = out_refund_no
          break
        end
      end
    end

    def as_refund_params
      slice(:out_trade_no, :out_refund_no, :refund_fee, :total_fee).to_options
    end
    # 发起退款成功
    # @param [Hash] result
    #
    # result example:
    #
    # {
    #   "return_code"=>"SUCCESS",
    #   "return_msg"=>"OK",
    #   "appid"=>"wxc5f2606121234cf",
    #   "mch_id"=>"1363241234",
    #   "sub_mch_id"=>"1525912341",
    #   "nonce_str"=>"RsXVcs0GMg2p5NRD",
    #   "sign"=>"F10AB3929B900DE4E189CA93B73D9D7A",
    #   "result_code"=>"SUCCESS",
    #   "transaction_id"=>"4200001199202106280049902399",
    #   "out_trade_no"=>"1624867410475591608",
    #   "out_refund_no"=>"1624867450917685776",
    #   "refund_id"=>"50301108952021062810183695009",
    #   "refund_channel"=>"",
    #   "refund_fee"=>"1",
    #   "coupon_refund_fee"=>"0",
    #   "total_fee"=>"1",
    #   "cash_fee"=>"1",
    #   "coupon_refund_count"=>"0",
    #   "cash_refund_fee"=>"1"
    # }
    def refund_apply_success(result)
      if payment_order.goods.respond_to? :refund_apply_success
        payment_order.goods.refund_apply_success(result)
      end

      update(
        refund_id: result["refund_id"],
        state: :pending
      )

      result
    end

    # 发起退款失败
    def refund_apply_failure(result)
      # TODO 没遇到过，待补充

      if payment_order.goods.respond_to? :refund_apply_failure
        payment_order.goods.refund_apply_failure(result)
      end
    end

    # 退款成功(回调)
    # @param [Hash] result
    #
    # result example:
    #
    # {
    #   "out_refund_no"=>"1624873658515277479",
    #   "out_trade_no"=>"1624873575281298144",
    #   "refund_account"=>"REFUND_SOURCE_RECHARGE_FUNDS",
    #   "refund_fee"=>"1",
    #   "refund_id"=>"50301308842021062810182580986",
    #   "refund_recv_accout"=>"招商银行信用卡4003",
    #   "refund_request_source"=>"API",
    #   "refund_status"=>"SUCCESS",
    #   "settlement_refund_fee"=>"1",
    #   "settlement_total_fee"=>"1",
    #   "success_time"=>"2021-06-28 17:47:47",
    #   "total_fee"=>"1",
    #   "transaction_id"=>"4200001202202106280268010129"
    # }
    def refund_exec_success(result)
      update(
        state: :refunded,
        refunded_at: Time.current
      )

      if payment_order.total_fee_refunded?
        payment_order.update(state: :refunded, refunded_at: Time.current)
      end

      if payment_order.goods.respond_to? :refund_exec_success
        payment_order.goods.refund_exec_success(result)
      end

      result
    end

    # 退款失败(回调)
    def refund_exec_failure(result)
      # TODO 待补充
      if payment_order.goods.respond_to? :refund_exec_failure
        payment_order.goods.refund_exec_failure(result)
      end
    end


  end
end
