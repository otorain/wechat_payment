module WechatPayment
  class Engine < ::Rails::Engine
    isolate_namespace WechatPayment

    config.autoload_paths << "#{config.root}/lib"
    config.i18n.default_locale = "zh-CN"
  end
end
