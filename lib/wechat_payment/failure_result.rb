
class WechatPayment::FailureResult < WechatPayment::ServiceResult
  def initialize(data: {}, error: nil, message: nil, message_kind: nil, message_type: nil)
    super(success: false, data: data, error: error, message: message, message_kind: message_kind, message_type: message_type)
  end

end
