
module WechatPayment
  class Client
    def initialize # (merchant = WxPay)
      # required_attrs = [:appid, :mch_id, :key, :app_secret, :cert_path]
      # missing_attrs = required_attrs.reject { |attr| merchant.respond_to?(attr) }
      # if missing_attrs.present?
      #   raise Exceptions::MerchantMissingAttr.new("Missing attributes: #{missing_attrs}, merchant target must respond to: appid, mch_id, key, appsecret, cert_path")
      # end
      #
      # @merchant = merchant
      # cert_path = Rails.root.join(merchant.cert_path)
      #
      # WxPay.appid = merchant.appid
      # WxPay.key = merchant.key
      # WxPay.mch_id = merchant.mch_id
      # WxPay.appsecret = merchant.app_secret
      # WxPay.set_apiclient_by_pkcs12(File.binread(cert_path), merchant.mch_id)
    end

    ORDER_REQUIRED_FIELD = [:out_trade_no, :spbill_create_ip, :body, :total_fee, :openid]
    # 下单
    def order(order_params)
      check_required_key!(order_params, ORDER_REQUIRED_FIELD)

      order_params.merge!(**WechatPayment.as_payment_params,
                          trade_type: :JSAPI,
                          notify_url: payment_notify_url)

      # 如果是服务商模式(根据参数中有没有 sub_appid 判断)，就把 openid 换成 sub_openid
      if order_params[:sub_appid]
        order_params[:sub_openid] = order_params.delete(:openid)
      end

      order_result = WxPay::Service.invoke_unifiedorder(order_params)

      if order_result.success?

        payment_logger.info("{params: #{order_params}, result: #{order_result}}")
        # WechatPayment::ServiceResult.new(success: true, data: { order_result: order_result.with_indifferent_access, js_payload: mini_program_request_params.with_indifferent_access })
        WechatPayment::ServiceResult.new(success: true, data: order_result.with_indifferent_access)
      else
        payment_logger.error("{params: #{order_params}, result: #{order_result}}")
        WechatPayment::ServiceResult.new(success: false, errors: order_result.with_indifferent_access)
      end
    end

    # 支付回调地址
    def payment_notify_url
      ENV["WECHAT_PAYMENT_NOTIFY_URL"] || "#{WechatPayment.host}/wechat_payment/callback/payment"
    end

    REFUND_REQUIRED_PARAMS = [:total_fee, :refund_fee, :out_trade_no, :out_refund_no]
    # 退款
    def refund(refund_params)
      check_required_key!(refund_params, REFUND_REQUIRED_PARAMS)

      refund_params.merge!(**WechatPayment.as_payment_params, notify_url: refund_notify_url)

      refund_result = WxPay::Service.invoke_refund(refund_params.to_options)

      if refund_result.success?
        refund_logger.info "{params: #{refund_params}, result: #{refund_result}"
        WechatPayment::ServiceResult.new(success: true, data: refund_result)
      else
        refund_logger.error "{params: #{refund_params}, result: #{refund_result}"
        WechatPayment::ServiceResult.new(success: false, errors: refund_result)
      end
    end

    # 退款回调地址
    def refund_notify_url
      ENV["WECHAT_REFUND_NOTIFY_URL"] || "#{WechatPayment.host}/wechat_payment/callback/refund"
    end

    # 处理支付回调
    def self.handle_payment_notify(notify_data)
      if !WxPay::Sign.verify?(notify_data)
        payment_logger.error("{msg: 签名验证失败, errors: #{notify_data}}")
        WechatPayment::ServiceResult.new(errors: notify_data, message: "回调签名验证失败")
      end

      result = WxPay::Result.new(notify_data)

      if result.success?
        payment_logger.info("{callback: #{notify_data}}")
        WechatPayment::ServiceResult.new(success: true, data: notify_data)
      else
        payment_logger.error("{callback: #{notify_data}}")
        WechatPayment::ServiceResult.new(errors: notify_data)
      end
    end

    # 处理退款回调
    def self.handle_refund_notify(encrypted_notify_data)
      notify_data = decrypt_refund_notify(encrypted_notify_data)

      result = WxPay::Result.new(notify_data)
      if result.success?
        refund_logger.info "{callback: #{notify_data}}"
        WechatPayment::ServiceResult.new(success: true, data: notify_data)
      else
        refund_logger.error "{callback: #{notify_data}}"
        WechatPayment::ServiceResult.new(errors: notify_data)
      end
    end

    # 解密退款回调数据
    def self.decrypt_refund_notify(decrypted_info)
      WxPay::Service.decrypt_refund_notify(decrypted_info)
    end

    # 生成下单成功后返回给前端拉起微信支付的数据结构
    def self.gen_js_pay_payload(order_result)
      payment_params = {
        prepayid: order_result["prepay_id"],
        noncestr: SecureRandom.hex(16)
      }

      # 如果是服务商的传 sub_appid ，否则 appid
      WxPay::Service.generate_js_pay_req(payment_params, { appid: WechatPayment.sub_appid || WechatPayment.appid })
    end

    private

    # 判断 hash 是否缺少 key
    def check_required_key!(data, required_keys)
      lack_of_keys = required_keys - data.keys.map(&:to_sym)

      if lack_of_keys.present?
        raise WechatPayment::MissingKeyError.new("Parameter missing keys: #{lack_of_keys}")
      end
    end

    # 支付日志
    def payment_logger
      WechatPayment::Client.payment_logger
    end

    # 退款日志
    def refund_logger
      WechatPayment::Client.refund_logger
    end

    def self.payment_logger
      @payment_logger ||= WechatPayment::RLogger.make("wx_payment")
    end

    def self.refund_logger
      @refund_logger ||= WechatPayment::RLogger.make("wx_refund")
    end
  end
end