require "wechat_payment/version"
require "wechat_payment/engine"

module WechatPayment
  mattr_accessor :appid, :app_secret, :mch_id, :sub_appid, :sub_app_secret, :sub_mch_id, :key, :cert_path, :host

  def self.setup
    yield self if block_given?
    WxPay.appid = appid
    WxPay.appsecret = app_secret
    WxPay.mch_id = mch_id
    WxPay.sub_appid = sub_appid
    WxPay.sub_mchid = sub_mch_id
    WxPay.key = key

    if cert_path
      WxPay.set_apiclient_by_pkcs12(File.binread(cert_path), mch_id)
    end
  end

  def self.as_payment_params
    {
      appid: appid,
      mch_id: mch_id,
      sub_appid: sub_appid,
      sub_mch_id: sub_mch_id
    }
  end

end
