
module WechatPayment
  class Client
    GATEWAY_URL = 'https://api.mch.weixin.qq.com'.freeze

    def initialize # (merchant = WechatPayment)
      # required_attrs = [:appid, :mch_id, :key, :app_secret, :cert_path]
      # missing_attrs = required_attrs.reject { |attr| merchant.respond_to?(attr) }
      # if missing_attrs.present?
      #   raise Exceptions::MerchantMissingAttr.new("Missing attributes: #{missing_attrs}, merchant target must respond to: appid, mch_id, key, appsecret, cert_path")
      # end
      #
      # @merchant = merchant
      # cert_path = Rails.root.join(merchant.cert_path)
      #
      # WechatPayment.appid = merchant.appid
      # WechatPayment.key = merchant.key
      # WechatPayment.mch_id = merchant.mch_id
      # WechatPayment.appsecret = merchant.app_secret
      # WechatPayment.set_apiclient_by_pkcs12(File.binread(cert_path), merchant.mch_id)
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

      order_result = invoke_unifiedorder(order_params)

      if order_result.success?

        payment_logger.info("{params: #{order_params}, result: #{order_result}}")
        WechatPayment::ServiceResult.new(success: true, data: order_result.with_indifferent_access)
      else
        payment_logger.error("{params: #{order_params}, result: #{order_result}}")
        WechatPayment::ServiceResult.new(success: false, error: order_result.with_indifferent_access)
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

      refund_result = invoke_refund(refund_params.to_options)

      if refund_result.success?
        refund_logger.info "{params: #{refund_params}, result: #{refund_result}"
        WechatPayment::ServiceResult.new(success: true, data: refund_result)
      else
        refund_logger.error "{params: #{refund_params}, result: #{refund_result}"
        WechatPayment::ServiceResult.new(success: false, error: refund_result)
      end
    end

    # 退款回调地址
    def refund_notify_url
      ENV["WECHAT_REFUND_NOTIFY_URL"] || "#{WechatPayment.host}/wechat_payment/callback/refund"
    end

    # 处理支付回调
    def self.handle_payment_notify(notify_data)
      if !WechatPayment::Sign.verify?(notify_data)
        payment_logger.error("{msg: 签名验证失败, error: #{notify_data}}")
        WechatPayment::ServiceResult.new(success: false, error: notify_data, message: "回调签名验证失败")
      end

      result = WechatPayment::InvokeResult.new(notify_data)

      if result.success?
        payment_logger.info("{callback: #{notify_data}}")
        WechatPayment::ServiceResult.new(success: true, data: notify_data, message: "支付执行成功", )
      else
        payment_logger.error("{callback: #{notify_data}}")
        WechatPayment::ServiceResult.new(success: false, error: notify_data, message: "支付执行失败", error_type: :payment_exec_failed)
      end
    end

    # 处理退款回调
    def self.handle_refund_notify(encrypted_notify_data)
      notify_data = decrypt_refund_notify(encrypted_notify_data)

      result = WechatPayment::InvokeResult.new(notify_data)
      if result.success?
        refund_logger.info "退款执行成功{callback: #{notify_data}}"
        WechatPayment::ServiceResult.new(success: true, data: notify_data)
      else
        refund_logger.error "退款执行失败: {callback: #{notify_data}}"
        WechatPayment::ServiceResult.new(success:false, error: notify_data, message: "退款回调失败")
      end
    end

    # 生成下单成功后返回给前端拉起微信支付的数据结构
    def self.gen_js_pay_payload(order_result, options = {})
      payment_params = {
        appId: WechatPayment.sub_appid || WechatPayment.appid,
        package: "prepay_id=#{order_result["prepay_id"]}",
        key: options.delete(:key) || WechatPayment.key,
        nonceStr: SecureRandom.hex(16),
        timeStamp: Time.now.to_i.to_s,
        signType: 'MD5'
      }

      payment_params[:paySign] = WechatPayment::Sign.generate(payment_params)

      payment_params
    end

    GENERATE_JS_PAY_REQ_REQUIRED_FIELDS = [:prepayid, :noncestr]
    def self.generate_js_pay_req(params, options = {})
      check_required_options(params, GENERATE_JS_PAY_REQ_REQUIRED_FIELDS)

      params = {
        appId: options.delete(:appid) || WechatPayment.appid,
        package: "prepay_id=#{params.delete(:prepayid)}",
        key: options.delete(:key) || WechatPayment.key,
        nonceStr: params.delete(:noncestr),
        timeStamp: Time.now.to_i.to_s,
        signType: 'MD5'
      }.merge(params)

      params[:paySign] = WechatPayment::Sign.generate(params)
      params
    end


    INVOKE_UNIFIEDORDER_REQUIRED_FIELDS = [:body, :out_trade_no, :total_fee, :spbill_create_ip, :notify_url, :trade_type]
    def invoke_unifiedorder(params, options = {})
      params = {
        appid: options.delete(:appid) || WechatPayment.appid,
        mch_id: options.delete(:mch_id) || WechatPayment.mch_id,
        key: options.delete(:key) || WechatPayment.key,
        nonce_str: SecureRandom.uuid.tr('-', '')
      }.merge(params)

      check_required_options(params, INVOKE_UNIFIEDORDER_REQUIRED_FIELDS)

      result = WechatPayment::InvokeResult.new(
        Hash.from_xml(
          invoke_remote("/pay/unifiedorder", make_payload(params), options)
        )
      )

      yield result if block_given?

      result
    end


    INVOKE_REFUND_REQUIRED_FIELDS = [:out_refund_no, :total_fee, :refund_fee, :op_user_id]
    # out_trade_no 和 transaction_id 是二选一(必填)
    def invoke_refund(params, options = {})
      params = {
        appid: options.delete(:appid) || WechatPayment.appid,
        mch_id: options.delete(:mch_id) || WechatPayment.mch_id,
        key: options.delete(:key) || WechatPayment.key,
        nonce_str: SecureRandom.uuid.tr('-', ''),
      }.merge(params)

      params[:op_user_id] ||= params[:mch_id]

      check_required_options(params, INVOKE_REFUND_REQUIRED_FIELDS)
      warn("WechatPayment Warn: missing required option: out_trade_no or transaction_id must have one") if ([:out_trade_no, :transaction_id] & params.keys) == []

      options = {
        cert: options.delete(:apiclient_cert) || WechatPayment.apiclient_cert,
        key: options.delete(:apiclient_key) || WechatPayment.apiclient_key,
        verify_mode: OpenSSL::SSL::VERIFY_NONE
      }.merge(options)

      result = WechatPayment::InvokeResult.new(
        Hash.from_xml(
          invoke_remote("/secapi/pay/refund", make_payload(params), options)
        )
      )

      yield result if block_given?

      result
    end

    # 解密微信退款回调信息
    #
    # result = Hash.from_xml(request.body.read)["xml"]
    #
    # data = WechatPayment::Service.decrypt_refund_notify(result)
    def self.decrypt_refund_notify(decrypted_data)
      aes = OpenSSL::Cipher::AES.new('256-ECB')
      aes.decrypt
      aes.key = Digest::MD5.hexdigest(WechatPayment.key)
      result = aes.update(Base64.decode64(decrypted_data)) + aes.final
      Hash.from_xml(result)["root"]
    end

    def make_payload(params, sign_type = WechatPayment::Sign::SIGN_TYPE_MD5)
      sign = WechatPayment::Sign.generate(params, sign_type)
      "<xml>#{params.except(:key).sort.map { |k, v| "<#{k}>#{v}</#{k}>" }.join}<sign>#{sign}</sign></xml>"
    end

    def check_required_options(options, names)
      names.each do |name|
        warn("WechatPayment Warn: missing required option: #{name}") unless options.has_key?(name)
      end
    end

    def invoke_remote(url, payload, options = {})
      uri = URI("#{GATEWAY_URL}#{url}")

      req = Net::HTTP::Post.new(uri)
      req['Content-Type'] = 'application/xml'

      options = {
        use_ssl: true
      }.merge(options)

      res = Net::HTTP.start(uri.hostname, uri.port, **options) do |http|
        http.use_ssl = true
        http.request(req, payload)
      end

      res.body
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