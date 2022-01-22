require "wechat_payment/version"
require "wechat_payment/engine"

module WechatPayment

  class << self
    attr_reader :apiclient_cert, :apiclient_key
    attr_accessor :appid, :app_secret, :mch_id, :sub_appid, :sub_app_secret, :sub_mch_id, :key, :cert_path, :host, :order_no_prefix
  end

  def self.setup
    yield self if block_given?

    if cert_path
      set_apiclient_by_pkcs12(File.binread(cert_path), mch_id)
    end
  end

  def self.set_apiclient_by_pkcs12(str, pass)
    pkcs12 = OpenSSL::PKCS12.new(str, pass)
    @apiclient_cert = pkcs12.certificate
    @apiclient_key = pkcs12.key

    pkcs12
  end

  def apiclient_cert=(cert)
    @apiclient_cert = OpenSSL::X509::Certificate.new(cert)
  end

  def apiclient_key=(key)
    @apiclient_key = OpenSSL::PKey::RSA.new(key)
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
