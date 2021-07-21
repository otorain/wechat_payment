module WechatPayment
  class Engine < ::Rails::Engine
    isolate_namespace WechatPayment

    config.autoload_paths << "#{config.root}/lib"
  end
end
