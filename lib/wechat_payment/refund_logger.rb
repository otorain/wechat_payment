
class WechatPayment::RefundLogger < WechatPayment::Logger
  def self.tags
    ["WechatPayment", "Refund"]
  end
end
