
module WechatPayment
  class CallbackController < WechatPayment::ApplicationController

    # 微信支付回调
    def payment
      result = Hash.from_xml(request.body.read)["xml"]

      process_result = WechatPayment::Service.handle_payment_notify(result)
      if process_result.success?
        render xml: { return_code: "SUCCESS" }.to_xml(root: 'xml', dasherize: false)
      else
        render xml: { return_code: "FAIL", return_msg: process_result.errors.first }.to_xml(root: 'xml', dasherize: false)
      end
    end

    def refund
      callback_info = Hash.from_xml(request.body.read)["xml"]["req_info"]
      refund_result = WechatPayment::Service.handle_refund_notify(callback_info)

      if refund_result.success?
        render xml: {return_code: "SUCCESS"}.to_xml(root: 'xml', dasherize: false)
      else
        render xml: {return_code: "FAIL", return_msg: refund_result.errors.first}.to_xml(root: 'xml', dasherize: false)
      end

    end

  end
end
