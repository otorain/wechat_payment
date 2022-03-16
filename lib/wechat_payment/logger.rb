
class WechatPayment::Logger
  def self.tags
    ["WechatPayment"]
  end

  %w{ info error warn fatal }.each do |level|
    define_singleton_method level do |content = "", &block|
      Rails.logger.tagged *self.tags do
        if block.present?
          Rails.logger.send(level, &block)
        else
          Rails.logger.send(level, content)
        end
      end
    end
  end
end
