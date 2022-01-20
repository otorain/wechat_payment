module WechatPayment
  class ServiceResult
    attr_accessor :success,
                  :error,
                  :data,
                  :message,
                  :message_type,
                  :error_type

    def initialize(success: false,
                   error: nil,
                   message: nil,
                   message_type: nil,
                   data: nil,
                   error_type: nil)
      self.success = success

      self.data = data.presence || {}

      if self.data.is_a? Hash
        self.data = self.data.with_indifferent_access
      end

      self.error = error

      self.message = message
      self.message_type = message_type
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

    def get_message_type
      if message_type.present?
        message_type.to_sym
      elsif success?
        :info
      else
        :error
      end
    end

    def as_json(options = {})
      # data.as_json(options)
      {
        success: success,
        data: data,
        message: message,
        message_type: get_message_type,
        error: error,
        error_type: error_type
      }
    end
  end
end
