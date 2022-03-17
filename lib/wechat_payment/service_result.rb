module WechatPayment
  class ServiceResult
    attr_accessor :success,
                  :error,
                  :data,
                  :message,
                  :message_kind,
                  :message_type

    def initialize(success: false,
                   data: {},
                   error: nil,
                   message: nil,
                   message_kind: nil,
                   message_type: nil)

      self.success = success
      self.data = (data || {}).with_indifferent_access
      self.error = error
      self.message = message
      self.message_type = message_type
      self.message_kind = message_kind
    end

    alias success? :success

    def failure?
      !success?
    end

    def on_success
      yield(self) if success?
    end

    def on_failure
      yield(self) if failure?
    end

    def message_type
      if @message_type.present?
        @message_type.to_sym
      elsif success?
        :info
      else
        :error
      end
    end

    def message_kind_prefix
      "wechat_payment_"
    end

    def message_kind
      "#{message_kind_prefix}#{@message_kind}"
    end

    def as_json(options = {})
      {
        success: success,
        data: data,
        message: message,
        error: error,
        message_kind: message_kind,
        message_type: message_type
      }
    end
  end
end
