class WechatPayment::PaymentLogger < WechatPayment::Logger

  def self.tags
    ["WechatPayment", "Pay"]
  end

end
