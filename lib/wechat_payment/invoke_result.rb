module WechatPayment
  class InvokeResult < ::Hash
    SUCCESS_FLAG = 'SUCCESS'.freeze

    def initialize(result)
      super nil # Or it will call `super result`

      if result['xml'].class == Hash
        result['xml'].each_pair do |k, v|
          self[k] = v
        end
      else
        result.each_pair do |k, v|
          self[k] = v
        end
      end
    end

    def success?
      payment_success? || refund_success?
    end

    def payment_success?
      self['return_code'] == SUCCESS_FLAG && self['result_code'] == SUCCESS_FLAG
    end

    def refund_success?
      self['refund_status'] == SUCCESS_FLAG
    end

    def failure?
      !success?
    end
  end
end
